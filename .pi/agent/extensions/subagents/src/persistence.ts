import { createHash, randomUUID } from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";
import {
  BACKEND_NAMES,
  REASONING_EFFORTS,
  type ReasoningEffort,
  type SubagentSnapshot,
} from "./domain.ts";

const STORE_VERSION = 1;
const WRITE_DEBOUNCE_MS = 200;
const DELIVERED_RETENTION_MS = 30 * 24 * 60 * 60 * 1_000;
const MAX_PERSISTED_RUNS = 128;

export interface PersistedSpawnSpec {
  readonly model?: string;
  readonly reasoningEffort?: ReasoningEffort;
}

export type DeliveryState = "pending" | "delivered";

export interface PersistedDelivery {
  readonly deliveryId: string;
  readonly state: DeliveryState;
  readonly snapshot: SubagentSnapshot;
}

export interface PersistedSubagentRun {
  readonly version: typeof STORE_VERSION;
  readonly parentSessionId: string;
  readonly parentSessionFile?: string;
  readonly spec: PersistedSpawnSpec;
  readonly snapshot: SubagentSnapshot;
  /** Every terminal generation remains here until retention cleanup. */
  readonly outbox: ReadonlyArray<PersistedDelivery>;
  readonly updatedAt: number;
}

function isSnapshot(value: unknown): value is SubagentSnapshot {
  if (!value || typeof value !== "object") return false;
  const record = value as Record<string, unknown>;
  return (
    typeof record.id === "string" &&
    typeof record.backend === "string" &&
    typeof record.title === "string" &&
    typeof record.prompt === "string" &&
    typeof record.cwd === "string" &&
    ["model", "btw"].includes(String(record.origin)) &&
    BACKEND_NAMES.includes(record.backend as (typeof BACKEND_NAMES)[number]) &&
    ["running", "recoverable", "done", "error"].includes(
      String(record.status),
    ) &&
    typeof record.createdAt === "number" &&
    Number.isInteger(record.generation) &&
    Number(record.generation) >= 1 &&
    !!record.meta &&
    typeof record.meta === "object" &&
    !!record.usage &&
    typeof record.usage === "object" &&
    Array.isArray(record.transcript) &&
    (record.liveAssistant === undefined ||
      (!!record.liveAssistant && typeof record.liveAssistant === "object")) &&
    Array.isArray(record.liveTools) &&
    Array.isArray(record.queued) &&
    typeof record.finalText === "string" &&
    typeof record.turns === "number"
  );
}

function parseRun(value: unknown): PersistedSubagentRun | undefined {
  if (!value || typeof value !== "object") return undefined;
  const record = value as Record<string, unknown>;
  if (
    record.version !== STORE_VERSION ||
    typeof record.parentSessionId !== "string" ||
    !isSnapshot(record.snapshot) ||
    !record.spec ||
    typeof record.spec !== "object" ||
    !Array.isArray(record.outbox)
  ) {
    return undefined;
  }
  const spec = record.spec as Record<string, unknown>;
  if (
    (spec.model !== undefined && typeof spec.model !== "string") ||
    (spec.reasoningEffort !== undefined &&
      !REASONING_EFFORTS.includes(
        spec.reasoningEffort as (typeof REASONING_EFFORTS)[number],
      ))
  ) {
    return undefined;
  }
  for (const item of record.outbox) {
    if (!item || typeof item !== "object") return undefined;
    const delivery = item as Record<string, unknown>;
    if (
      typeof delivery.deliveryId !== "string" ||
      !["pending", "delivered"].includes(String(delivery.state)) ||
      !isSnapshot(delivery.snapshot)
    ) {
      return undefined;
    }
  }
  return value as PersistedSubagentRun;
}

function safeName(value: string) {
  return value.replace(/[^a-zA-Z0-9._-]/g, "_");
}

function atomicWriteJson(file: string, value: unknown) {
  const directory = path.dirname(file);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  try {
    fs.chmodSync(directory, 0o700);
  } catch {
    // Best effort on platforms without POSIX permissions.
  }

  const temporary = path.join(
    directory,
    `.${path.basename(file)}.${process.pid}.${randomUUID()}.tmp`,
  );
  const fd = fs.openSync(temporary, "wx", 0o600);
  try {
    fs.writeFileSync(fd, `${JSON.stringify(value)}\n`, "utf8");
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(temporary, file);
  try {
    fs.chmodSync(file, 0o600);
  } catch {
    // Best effort on platforms without POSIX permissions.
  }
}

/** Stable receipt identity for one terminal result. */
export function subagentDeliveryId(snapshot: SubagentSnapshot) {
  if (snapshot.status === "running" || snapshot.status === "recoverable") {
    return undefined;
  }
  return createHash("sha256")
    .update(snapshot.id)
    .update("\0")
    .update(String(snapshot.generation))
    .update("\0")
    .update(snapshot.status)
    .update("\0")
    .update(snapshot.errorText ?? "")
    .update("\0")
    .update(snapshot.finalText)
    .digest("hex");
}

function copySnapshot(snapshot: SubagentSnapshot): SubagentSnapshot {
  return {
    ...snapshot,
    meta: { ...snapshot.meta },
    usage: { ...snapshot.usage },
    transcript: snapshot.transcript.map((item) =>
      item.kind === "assistant"
        ? { ...item, parts: item.parts.map((part) => ({ ...part })) }
        : { ...item },
    ),
    liveAssistant: snapshot.liveAssistant
      ? { ...snapshot.liveAssistant }
      : undefined,
    liveTools: snapshot.liveTools.map((tool) => ({ ...tool })),
    queued: snapshot.queued.map((message) => ({ ...message })),
  };
}

function withPendingDelivery(
  outbox: ReadonlyArray<PersistedDelivery>,
  snapshot: SubagentSnapshot,
) {
  const durableSnapshot = copySnapshot(snapshot);
  const deliveryId = subagentDeliveryId(durableSnapshot);
  if (!deliveryId || outbox.some((item) => item.deliveryId === deliveryId)) {
    return { outbox, deliveryId };
  }
  return {
    deliveryId,
    outbox: [
      ...outbox,
      {
        deliveryId,
        state: "pending" as const,
        snapshot: durableSnapshot,
      },
    ],
  };
}

/**
 * Private, per-parent-session ledger. Native harness transcripts remain the
 * source of conversation context; this store preserves orchestration state,
 * UI snapshots, recovery handles, and result-delivery receipts.
 */
export class SubagentRunStore {
  private readonly directory: string;
  private readonly parentSessionId: string;
  private readonly parentSessionFile?: string;
  private readonly records = new Map<string, PersistedSubagentRun>();
  private readonly timers = new Map<string, ReturnType<typeof setTimeout>>();

  constructor(
    agentDir: string,
    parentSessionId: string,
    parentSessionFile?: string,
  ) {
    this.parentSessionId = parentSessionId;
    this.parentSessionFile = parentSessionFile;
    this.directory = path.join(
      agentDir,
      "state",
      "subagents",
      `v${STORE_VERSION}`,
      safeName(parentSessionId),
    );
  }

  load() {
    this.records.clear();
    let names: string[];
    try {
      names = fs.readdirSync(this.directory);
    } catch {
      return [];
    }

    for (const name of names) {
      if (!name.endsWith(".json")) continue;
      try {
        const parsed = parseRun(
          JSON.parse(fs.readFileSync(path.join(this.directory, name), "utf8")),
        );
        if (!parsed || parsed.parentSessionId !== this.parentSessionId) continue;
        const snapshot: SubagentSnapshot =
          parsed.snapshot.status === "running"
            ? {
                ...parsed.snapshot,
                status: "recoverable",
                settledAt: parsed.snapshot.settledAt ?? Date.now(),
                errorText:
                  parsed.snapshot.errorText ??
                  "Parent session ended while this subagent was running",
                liveAssistant: undefined,
                liveTools: [],
                queued: [],
              }
            : parsed.snapshot;
        this.records.set(snapshot.id, { ...parsed, snapshot });
      } catch {
        // One corrupt/truncated record must not hide the other runs.
      }
    }

    this.pruneDelivered();
    return [...this.records.values()].sort(
      (a, b) => a.snapshot.createdAt - b.snapshot.createdAt,
    );
  }

  get(id: string) {
    return this.records.get(id);
  }

  register(snapshot: SubagentSnapshot, spec: PersistedSpawnSpec) {
    const { outbox } = withPendingDelivery([], snapshot);
    const record: PersistedSubagentRun = {
      version: STORE_VERSION,
      parentSessionId: this.parentSessionId,
      parentSessionFile: this.parentSessionFile,
      spec,
      snapshot: copySnapshot(snapshot),
      outbox,
      updatedAt: Date.now(),
    };
    this.records.set(snapshot.id, record);
    this.write(record);
  }

  schedule(snapshot: SubagentSnapshot) {
    const current = this.records.get(snapshot.id);
    if (!current) return;
    this.records.set(snapshot.id, {
      ...current,
      snapshot: copySnapshot(snapshot),
      updatedAt: Date.now(),
    });
    if (this.timers.has(snapshot.id)) return;
    this.timers.set(
      snapshot.id,
      setTimeout(() => {
        this.timers.delete(snapshot.id);
        const latest = this.records.get(snapshot.id);
        if (latest) this.write(latest);
      }, WRITE_DEBOUNCE_MS),
    );
  }

  saveTerminal(snapshot: SubagentSnapshot) {
    const current = this.records.get(snapshot.id);
    if (!current) return undefined;
    this.clearTimer(snapshot.id);
    const { outbox, deliveryId } = withPendingDelivery(
      current.outbox,
      snapshot,
    );
    const record: PersistedSubagentRun = {
      ...current,
      snapshot: copySnapshot(snapshot),
      outbox,
      updatedAt: Date.now(),
    };
    this.records.set(snapshot.id, record);
    this.write(record);
    return deliveryId;
  }

  markDelivered(deliveryIds: ReadonlySet<string>) {
    for (const [id, record] of this.records) {
      let changed = false;
      const outbox = record.outbox.map((delivery) => {
        if (
          delivery.state === "delivered" ||
          !deliveryIds.has(delivery.deliveryId)
        ) {
          return delivery;
        }
        changed = true;
        return { ...delivery, state: "delivered" as const };
      });
      if (!changed) continue;
      const next = { ...record, outbox, updatedAt: Date.now() };
      this.records.set(id, next);
      this.write(next);
    }
  }

  /** Flush all live snapshots, conservatively checkpointing active runs. */
  close(snapshots: ReadonlyArray<SubagentSnapshot>) {
    for (const timer of this.timers.values()) clearTimeout(timer);
    this.timers.clear();
    for (const snapshot of snapshots) {
      const current = this.records.get(snapshot.id);
      if (!current) continue;
      const persistedSnapshot: SubagentSnapshot =
        snapshot.status === "running"
          ? {
              ...snapshot,
              status: "recoverable",
              settledAt: Date.now(),
              errorText: "Parent session ended while this subagent was running",
              liveAssistant: undefined,
              liveTools: [],
              queued: [],
            }
          : snapshot;
      const { outbox } = withPendingDelivery(
        current.outbox,
        persistedSnapshot,
      );
      const next = {
        ...current,
        snapshot: copySnapshot(persistedSnapshot),
        outbox,
        updatedAt: Date.now(),
      };
      this.records.set(snapshot.id, next);
      this.write(next);
    }
  }

  private pruneDelivered() {
    const now = Date.now();
    const candidates = [...this.records.values()]
      .filter(
        (record) =>
          record.snapshot.status !== "running" &&
          record.snapshot.status !== "recoverable" &&
          record.outbox.length > 0 &&
          record.outbox.every((delivery) => delivery.state === "delivered"),
      )
      .sort((a, b) => a.updatedAt - b.updatedAt);
    for (const record of candidates) {
      const expired = now - record.updatedAt > DELIVERED_RETENTION_MS;
      const overLimit = this.records.size > MAX_PERSISTED_RUNS;
      if (!expired && !overLimit) continue;
      this.records.delete(record.snapshot.id);
      try {
        fs.unlinkSync(
          path.join(this.directory, `${safeName(record.snapshot.id)}.json`),
        );
      } catch {
        // Retention is best-effort; a later startup retries the cleanup.
      }
    }
  }

  private clearTimer(id: string) {
    const timer = this.timers.get(id);
    if (timer) clearTimeout(timer);
    this.timers.delete(id);
  }

  private write(record: PersistedSubagentRun) {
    atomicWriteJson(
      path.join(this.directory, `${safeName(record.snapshot.id)}.json`),
      record,
    );
  }
}
