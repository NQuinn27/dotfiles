/**
 * Subagents — spawn background subagents on one of three backends
 * (pi, Claude Code, Codex) unified behind a single Effect service interface.
 *
 * Tools (for the parent LLM):
 * - subagent_spawn: fire-and-forget spawn (prompt, title, agent, working_dir,
 *   model, reasoning_effort). Max 4 running at once across all backends.
 * - subagent_resume: explicitly continue a recovered native conversation.
 * - subagent_wait: block until the listed subagents settle, return results.
 * - subagent_cancel: stop one or more running subagents.
 * - subagent_check: peek at a subagent's status and recent activity.
 * - subagent_list: list all subagents.
 *
 * Unawaited subagents queue their result as a follow-up message when they
 * settle. Durable per-parent records restore results and native conversation
 * handles after restart. `/subagents` opens a picker + takeover view.
 *
 * Architecture: Effect v4 generators throughout (backends -> manager ->
 * runtime); this file is the async boundary where tool handlers run effects
 * against one shared ManagedRuntime. All three backends are real: pi runs
 * in-process SDK sessions, claude drives the Claude Agent SDK, codex speaks
 * JSON-RPC to a scoped `codex app-server` process.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ExtensionUIContext,
  ThemeColor,
} from "@earendil-works/pi-coding-agent";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  getAgentDir,
  getMarkdownTheme,
  ProjectTrustStore,
  truncateHead,
} from "@earendil-works/pi-coding-agent";
import { Markdown, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { deriveBtwTitle, isModelVisible } from "./src/by-the-way.ts";
import {
  BACKEND_NAMES,
  formatElapsed,
  latestText,
  REASONING_EFFORTS,
  type SubagentSnapshot,
} from "./src/domain.ts";
import {
  formatActivityStatus,
  formatContextUtilization,
} from "./src/format.ts";
import { SubagentManager, type SubagentManagerShape } from "./src/manager.ts";
import {
  buildSubagentResultMessage,
  buildSubagentSpawnResult,
  SUBAGENT_CANCEL_PARAMETER_DESCRIPTIONS,
  SUBAGENT_CANCEL_TOOL_DESCRIPTION,
  SUBAGENT_CHECK_PARAMETER_DESCRIPTIONS,
  SUBAGENT_CHECK_TOOL_DESCRIPTION,
  SUBAGENT_LIST_TOOL_DESCRIPTION,
  SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS,
  SUBAGENT_SPAWN_PROMPT_GUIDELINES,
  SUBAGENT_SPAWN_PROMPT_SNIPPET,
  SUBAGENT_SPAWN_TOOL_DESCRIPTION,
  SUBAGENT_WAIT_PARAMETER_DESCRIPTIONS,
  SUBAGENT_WAIT_TOOL_DESCRIPTION,
} from "./src/prompt.ts";
import { createDeferredResultDelivery } from "./src/result-delivery.ts";
import {
  SubagentRunStore,
  subagentDeliveryId,
  type PersistedSubagentRun,
} from "./src/persistence.ts";
import {
  HerdrPaneController,
  type HerdrPaneMode,
} from "./src/herdr/controller.ts";
import { isInsideHerdr } from "./src/herdr/environment.ts";
import {
  createSubagentRuntime,
  runTool,
  type SubagentRuntime,
} from "./src/runtime.ts";
import { openSubagentPicker, openSubagentTakeover } from "./src/ui/takeover.ts";

const SUBAGENT_OUTPUT_MAX_BYTES = 24 * 1024;
const WAIT_OUTPUT_MAX_BYTES = 48 * 1024;
const WAIT_PER_AGENT_MAX_BYTES = 16 * 1024;
const HERDR_THEME_COLORS = [
  "accent",
  "border",
  "borderAccent",
  "success",
  "error",
  "warning",
  "muted",
  "dim",
  "text",
  "userMessageText",
  "toolTitle",
  "toolOutput",
  "thinkingText",
] satisfies ReadonlyArray<ThemeColor>;
function defaultRecoveryPrompt(record: PersistedSubagentRun) {
  return (
    "The parent session ended during or after your previous work. Continue the task below from the current workspace and native conversation. First inspect the existing state, do not repeat completed side-effecting steps, and return a final report.\n\nOriginal task:\n" +
    record.snapshot.prompt
  );
}

interface BtwResultData {
  readonly id: string;
  readonly title: string;
  readonly status: SubagentSnapshot["status"];
  readonly errorText?: string;
  readonly prompt: string;
  readonly answer: string;
  readonly sessionFilePath?: string;
  readonly deliveryId?: string;
}

function describeSubagent(snap: SubagentSnapshot) {
  const details = [
    `${snap.backend}: ${snap.meta.modelLabel ?? "?"}`,
    formatContextUtilization(snap.usage),
    formatElapsed(snap),
    snap.cwd,
  ].filter(Boolean);
  return `${snap.id} [${snap.status}] "${snap.title}" (${details.join(", ")})`;
}

function truncatedOutput(
  snap: SubagentSnapshot,
  maxBytes = SUBAGENT_OUTPUT_MAX_BYTES,
): string {
  const output = snap.finalText || "(no output)";
  const truncation = truncateHead(output, {
    maxBytes: Math.min(maxBytes, DEFAULT_MAX_BYTES),
    maxLines: Math.min(600, DEFAULT_MAX_LINES),
  });
  let text = truncation.content;
  if (truncation.truncated) {
    text += `\n\n[Output truncated: ${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)} shown. Full transcript in session file: ${snap.meta.sessionFilePath ?? "?"}]`;
  }
  return text;
}

/**
 * Same-directory children inherit the live parent decision. An alternate cwd
 * is trusted only when pi's persisted trust store explicitly trusts it (or a
 * containing directory); unreadable/invalid trust data fails closed.
 */
function deliveredResultIds(entries: ReadonlyArray<unknown>) {
  const ids = new Set<string>();
  for (const value of entries) {
    if (!value || typeof value !== "object") continue;
    const entry = value as {
      type?: string;
      data?: { deliveryId?: unknown };
      details?: { deliveryId?: unknown };
      message?: {
        role?: string;
        toolName?: string;
        customType?: string;
        details?: {
          deliveryId?: unknown;
          results?: ReadonlyArray<{ deliveryId?: unknown }>;
        };
      };
    };
    const direct = entry.data?.deliveryId ?? entry.details?.deliveryId;
    if (typeof direct === "string") ids.add(direct);
    const details = entry.message?.details;
    if (typeof details?.deliveryId === "string") ids.add(details.deliveryId);
    const results = details?.results;
    if (Array.isArray(results)) {
      for (const result of results) {
        if (typeof result?.deliveryId === "string") ids.add(result.deliveryId);
      }
    }
  }
  return ids;
}

function resolveChildProjectTrust(options: {
  parentCwd: string;
  childCwd: string;
  parentTrusted: boolean;
}) {
  if (path.resolve(options.childCwd) === path.resolve(options.parentCwd)) {
    return options.parentTrusted;
  }
  try {
    const trustStore = new ProjectTrustStore(getAgentDir());
    return trustStore.get(options.childCwd) === true;
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  let runtime: SubagentRuntime | undefined;
  let managerPromise: Promise<SubagentManagerShape> | undefined;
  let sessionContext: ExtensionContext | undefined;
  let ui: ExtensionUIContext | undefined;
  let unsubStatus: (() => void) | undefined;
  let herdrPaneMode: HerdrPaneMode = "manual";
  let herdrControllerPromise: Promise<HerdrPaneController> | undefined;
  let runStore: SubagentRunStore | undefined;
  const resultDelivery = createDeferredResultDelivery<SubagentSnapshot>(
    (snapshot) => subagentDeliveryId(snapshot) ?? snapshot.id,
  );

  const getRuntime = () => (runtime ??= createSubagentRuntime());

  /** Resolve the manager service once per runtime and wire the extension hooks. */
  const getManager = () => {
    managerPromise ??= getRuntime()
      .runPromise(SubagentManager)
      .then((manager) => {
        manager.view.setOnSettled(onSettled);
        unsubStatus?.();
        unsubStatus = manager.view.subscribe(() => {
          updateStatus(manager);
          const store = runStore;
          if (store) {
            for (const snapshot of manager.view.list()) store.schedule(snapshot);
          }
        });
        updateStatus(manager);
        return manager;
      });
    return managerPromise;
  };

  const updateStatus = (manager: SubagentManagerShape) => {
    if (!ui) return;
    const subs = manager.view.list();
    if (subs.length === 0) {
      ui.setStatus("subagents", undefined);
      return;
    }
    const running = subs.filter((snap) => snap.status === "running").length;
    const recoverable = subs.filter(
      (snap) => snap.status === "recoverable",
    ).length;
    const failed = subs.filter((snap) => snap.status === "error").length;
    const done = subs.length - running - recoverable - failed;
    ui.setStatus(
      "subagents",
      formatActivityStatus(ui.theme, {
        running,
        recoverable,
        done,
        failed,
      }),
    );
  };

  const deliverResult = (snap: SubagentSnapshot) => {
    const deliveryId = subagentDeliveryId(snap);
    pi.sendMessage(
      {
        customType: "subagent-result",
        content: buildSubagentResultMessage({
          id: snap.id,
          title: snap.title,
          status: snap.status,
          errorText: snap.errorText,
          output: truncatedOutput(snap),
        }),
        display: true,
        details: {
          id: snap.id,
          title: snap.title,
          status: snap.status,
          deliveryId,
        },
      },
      { deliverAs: "followUp", triggerTurn: true },
    );
  };

  const flushResults = () => {
    for (const snap of resultDelivery.drain()) deliverResult(snap);
  };

  const getHerdrController = async () => {
    if (!sessionContext || !isInsideHerdr()) {
      throw new Error("This Pi session is not running inside Herdr.");
    }
    herdrControllerPromise ??= getManager().then((manager) =>
      new HerdrPaneController({
        parentPaneId: process.env.HERDR_PANE_ID!,
        parentSessionId: sessionContext!.sessionManager.getSessionId(),
        themeName: ui?.theme.name,
        themePalette: ui
          ? Object.fromEntries(
              HERDR_THEME_COLORS.map((color) => [
                color,
                ui!.theme.getFgAnsi(color),
              ]),
            )
          : undefined,
        view: manager.view,
        actions: {
          send: (id, text) =>
            runTool(getRuntime(), manager.send(id, text), {
              interruptMessage: "Subagent message was interrupted.",
            }),
          abort: (id) => {
            const snap = manager.view.get(id);
            if (!snap) throw new Error(`Unknown subagent "${id}".`);
            if (snap.status !== "running") {
              throw new Error(`Subagent "${id}" is already ${snap.status}.`);
            }
            manager.view.requestAbort(id);
          },
        },
      }),
    );
    return herdrControllerPromise;
  };

  const closeHerdrController = async () => {
    const pending = herdrControllerPromise;
    herdrControllerPromise = undefined;
    if (!pending) return;
    try {
      await (await pending).closeAll();
    } catch {
      // Pane cleanup is best-effort during extension/session shutdown.
    }
  };

  const openHerdrPane = async (id: string, notifyOnError: boolean) => {
    try {
      const controller = await getHerdrController();
      const paneId = await controller.open(id);
      if (notifyOnError && paneId) ui?.notify(`Opened ${id} in Herdr pane ${paneId}`, "info");
      return paneId;
    } catch (error) {
      if (notifyOnError) {
        ui?.notify(error instanceof Error ? error.message : String(error), "error");
      }
      return undefined;
    }
  };

  const deliverBtwResult = (snap: SubagentSnapshot) => {
    // appendEntry is a synchronous SessionManager operation and emits an
    // entry_appended event, so it is safe while the parent is streaming and
    // never enters the model's context or follow-up queue.
    pi.appendEntry<BtwResultData>("btw-result", {
      id: snap.id,
      title: snap.title,
      status: snap.status,
      errorText: snap.errorText,
      prompt: snap.prompt,
      answer: truncatedOutput(snap),
      sessionFilePath: snap.meta.sessionFilePath,
      deliveryId: subagentDeliveryId(snap),
    });
    const deliveryId = subagentDeliveryId(snap);
    if (deliveryId) runStore?.markDelivered(new Set([deliveryId]));
    ui?.notify(
      snap.status === "error"
        ? `by the way “${snap.title}” failed — reopen it with /subagents`
        : `by the way “${snap.title}” answered — reopen it with /subagents`,
      snap.status === "error" ? "error" : "info",
    );
  };

  const onSettled = (snap: SubagentSnapshot, consumed: boolean) => {
    runStore?.saveTerminal(snap);
    // A shutdown can settle children while disposing their scopes. Never
    // append into a session whose extension runtime is already closing.
    if (!sessionContext) return;
    if (snap.origin === "btw") {
      deliverBtwResult({ ...snap, meta: { ...snap.meta } });
      return;
    }
    if (consumed) {
      const deliveryId = subagentDeliveryId(snap);
      if (deliveryId) resultDelivery.consumeKeys([deliveryId]);
      return;
    }
    // Keep the result retractable while the parent is working. A later
    // subagent_wait can consume it before agent_settled flushes follow-ups.
    // Defer a copy: the live snapshot keeps mutating if the subagent is
    // restarted before the deferred result flushes.
    resultDelivery.defer({ ...snap, meta: { ...snap.meta } });
    if (sessionContext?.isIdle()) flushResults();
  };

  const recoveryTask = (
    record: PersistedSubagentRun,
    ctx: ExtensionContext,
  ) => ({
    origin: record.snapshot.origin,
    prompt: record.snapshot.prompt,
    title: record.snapshot.title,
    cwd: record.snapshot.cwd,
    model: record.spec.model,
    reasoningEffort: record.spec.reasoningEffort,
    parent: {
      parentCwd: ctx.cwd,
      projectTrusted: resolveChildProjectTrust({
        parentCwd: ctx.cwd,
        childCwd: record.snapshot.cwd,
        parentTrusted: ctx.isProjectTrusted(),
      }),
      inheritedModel: ctx.model
        ? { provider: ctx.model.provider, id: ctx.model.id }
        : undefined,
      inheritedThinkingLevel: pi.getThinkingLevel(),
      modelRegistry: ctx.modelRegistry,
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    sessionContext = ctx;
    herdrPaneMode = "manual";
    if (ctx.hasUI) ui = ctx.ui;

    const store = new SubagentRunStore(
      getAgentDir(),
      ctx.sessionManager.getSessionId(),
      ctx.sessionManager.getSessionFile(),
    );
    runStore = store;
    const records = store.load();
    store.markDelivered(
      deliveredResultIds(ctx.sessionManager.getBranch()),
    );
    if (records.length === 0) return;

    const manager = await getManager();
    await runTool(
      getRuntime(),
      manager.restore(
        records.map((record) => ({
          snapshot: record.snapshot,
          task: recoveryTask(record, ctx),
        })),
      ),
    );

    let recoverable = 0;
    let pending = 0;
    for (const original of records) {
      const record = store.get(original.snapshot.id) ?? original;
      const snap = manager.view.get(record.snapshot.id);
      if (!snap) continue;
      if (snap.status === "recoverable") recoverable++;
      for (const delivery of record.outbox) {
        if (delivery.state !== "pending") continue;
        pending++;
        const result = delivery.snapshot;
        if (result.origin === "btw") deliverBtwResult(result);
        else resultDelivery.defer({ ...result, meta: { ...result.meta } });
      }
    }
    if (ctx.isIdle()) flushResults();
    if (ctx.hasUI && (recoverable > 0 || pending > 0)) {
      ctx.ui.notify(
        `Recovered ${records.length} subagent${records.length === 1 ? "" : "s"}: ${recoverable} resumable, ${pending} result${pending === 1 ? "" : "s"} pending.`,
        "info",
      );
    }
  });

  pi.on("agent_settled", flushResults);

  pi.on("session_shutdown", async () => {
    await closeHerdrController();
    const currentManager = await managerPromise?.catch(() => undefined);
    runStore?.close(currentManager?.view.list() ?? []);
    runStore = undefined;
    sessionContext = undefined;
    resultDelivery.clear();
    unsubStatus?.();
    unsubStatus = undefined;
    ui?.setStatus("subagents", undefined);
    ui = undefined;
    const closing = runtime;
    runtime = undefined;
    managerPromise = undefined;
    // Disposing the runtime runs the manager finalizer, which tears down all
    // subagent scopes. Their durable handles remain recoverable next time the
    // owning parent session is opened.
    await closing?.dispose();
  });

  // --- Tools -------------------------------------------------------------

  pi.registerTool({
    name: "subagent_spawn",
    label: "Spawn Subagent",
    description: SUBAGENT_SPAWN_TOOL_DESCRIPTION,
    promptSnippet: SUBAGENT_SPAWN_PROMPT_SNIPPET,
    promptGuidelines: SUBAGENT_SPAWN_PROMPT_GUIDELINES,
    parameters: Type.Object({
      prompt: Type.String({
        description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.prompt,
      }),
      name: Type.String({
        description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.name,
      }),
      harness: StringEnum(BACKEND_NAMES, {
        description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.harness,
      }),
      working_dir: Type.Optional(
        Type.String({
          description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.workingDir,
        }),
      ),
      model: Type.Optional(
        Type.String({
          description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.model,
        }),
      ),
      reasoning_effort: Type.Optional(
        StringEnum(REASONING_EFFORTS, {
          description: SUBAGENT_SPAWN_PARAMETER_DESCRIPTIONS.reasoningEffort,
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const manager = await getManager();
      const harness = params.harness;

      const cwd = path.resolve(ctx.cwd, params.working_dir ?? ".");
      if (!fs.existsSync(cwd) || !fs.statSync(cwd).isDirectory()) {
        throw new Error(`working_dir is not a directory: ${cwd}`);
      }

      const title = params.name.trim().slice(0, 160) || "subagent";
      const snap = await runTool(
        getRuntime(),
        manager.spawn(
          harness,
          {
            prompt: params.prompt,
            title,
            cwd,
            model: params.model,
            reasoningEffort: params.reasoning_effort,
            parent: {
              parentCwd: ctx.cwd,
              projectTrusted: resolveChildProjectTrust({
                parentCwd: ctx.cwd,
                childCwd: cwd,
                parentTrusted: ctx.isProjectTrusted(),
              }),
              inheritedModel: ctx.model
                ? { provider: ctx.model.provider, id: ctx.model.id }
                : undefined,
              inheritedThinkingLevel: pi.getThinkingLevel(),
              modelRegistry: ctx.modelRegistry,
            },
          },
          (ready) => {
            if (!runStore) {
              throw new Error("Subagent recovery ledger is unavailable.");
            }
            runStore.register(ready, {
              model: params.model,
              reasoningEffort: params.reasoning_effort,
            });
            pi.appendEntry("subagent-run", {
              id: ready.id,
              harness,
              title: ready.title,
              cwd,
              nativeSessionId: ready.meta.nativeSessionId,
              sessionFilePath: ready.meta.sessionFilePath,
            });
          },
        ),
        { signal, interruptMessage: "Subagent spawn aborted." },
      );

      const herdrPaneId =
        herdrPaneMode === "auto" ? await openHerdrPane(snap.id, true) : undefined;

      return {
        content: [
          {
            type: "text",
            text: buildSubagentSpawnResult({
              id: snap.id,
              title: snap.title,
              harness,
              modelLabel: snap.meta.modelLabel ?? "?",
              cwd,
            }),
          },
        ],
        details: {
          id: snap.id,
          title: snap.title,
          cwd,
          harness,
          model: snap.meta.modelLabel,
          herdrPaneId,
        },
      };
    },
  });

  pi.registerTool({
    name: "subagent_resume",
    label: "Resume Subagent",
    description:
      "Resume a persisted subagent conversation after its parent session ended. This starts a new continuation turn from the native Pi, Claude Code, or Codex transcript; it never blindly replays the interrupted turn.",
    promptSnippet:
      "Explicitly continue a recoverable subagent from its native conversation",
    promptGuidelines: [
      "Use subagent_resume only for a recoverable subagent; inspect existing state before repeating side-effecting work.",
    ],
    parameters: Type.Object({
      id: Type.String({ description: "Persisted subagent id to resume" }),
      prompt: Type.Optional(
        Type.String({
          description:
            "Continuation instruction. Defaults to safely continuing the original task after inspecting existing work.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const manager = await getManager();
      const snap = manager.view.get(params.id);
      if (!snap || !isModelVisible(snap)) {
        throw new Error(`Unknown subagent id "${params.id}".`);
      }
      if (snap.status === "running") {
        throw new Error(`Subagent "${params.id}" is already running.`);
      }
      const record = runStore?.get(params.id);
      if (!record) {
        throw new Error(
          `Subagent "${params.id}" has no durable recovery record.`,
        );
      }
      const continuation =
        params.prompt?.trim() || defaultRecoveryPrompt(record);
      await runTool(
        getRuntime(),
        manager.resume(
          params.id,
          recoveryTask(record, ctx),
          continuation,
        ),
        { signal, interruptMessage: "Subagent resume aborted." },
      );
      return {
        content: [
          {
            type: "text",
            text: `Resumed ${params.id} "${snap.title}" from its ${snap.backend} conversation.`,
          },
        ],
        details: { id: params.id, status: "running" },
      };
    },
  });

  pi.registerTool({
    name: "subagent_wait",
    label: "Wait for Subagents",
    description: SUBAGENT_WAIT_TOOL_DESCRIPTION,
    parameters: Type.Object({
      ids: Type.Array(Type.String(), {
        maxItems: 64,
        description: SUBAGENT_WAIT_PARAMETER_DESCRIPTIONS.ids,
      }),
    }),
    async execute(_toolCallId, params, signal, onUpdate) {
      const manager = await getManager();
      const ids = [...new Set(params.ids)];
      if (ids.length === 0)
        throw new Error("Provide at least one subagent id.");
      const known = manager.view
        .list()
        .filter(isModelVisible)
        .map((snap) => snap.id);
      const unknown = ids.filter((id) => {
        const snap = manager.view.get(id);
        return !snap || !isModelVisible(snap);
      });
      if (unknown.length > 0) {
        throw new Error(
          `Unknown subagent id(s): ${unknown.join(", ")}. Known: ${known.join(", ") || "none"}.`,
        );
      }
      const recoverable = ids.filter(
        (id) => manager.view.get(id)?.status === "recoverable",
      );
      if (recoverable.length > 0) {
        throw new Error(
          `Subagent id(s) ${recoverable.join(", ")} were interrupted with their parent session. Resume them with subagent_resume before waiting.`,
        );
      }

      await runTool(
        getRuntime(),
        manager.waitFor(ids, (pending) => {
          onUpdate?.({
            content: [
              { type: "text", text: `Waiting for ${pending.join(", ")}...` },
            ],
            details: { pending },
          });
        }),
        { signal, interruptMessage: "Wait aborted. Subagents keep running." },
      );

      // Settlement may have happened before this wait began. Remove only the
      // generations this wait returns; older pending generations stay queued.
      resultDelivery.consumeKeys(
        ids.flatMap((id) => {
          const snap = manager.view.get(id);
          const deliveryId = snap ? subagentDeliveryId(snap) : undefined;
          return deliveryId ? [deliveryId] : [];
        }),
      );

      const sections: string[] = [];
      let remainingBytes = WAIT_OUTPUT_MAX_BYTES;
      for (const id of ids) {
        const snap = manager.view.get(id);
        if (!snap) {
          sections.push(`## ${id}\n\n(no longer tracked)`);
          continue;
        }
        const verb = snap.status === "error" ? "failed" : "finished";
        let section = `## ${snap.id} "${snap.title}" ${verb}`;
        if (snap.errorText) section += `\nError: ${snap.errorText}`;
        const headerBytes = Buffer.byteLength(section, "utf8") + 2;
        const outputBudget = Math.max(
          512,
          Math.min(WAIT_PER_AGENT_MAX_BYTES, remainingBytes - headerBytes),
        );
        section += `\n\n${truncatedOutput(snap, outputBudget)}`;
        const sectionBytes = Buffer.byteLength(section, "utf8");
        if (sectionBytes > remainingBytes) {
          sections.push(
            `## ${snap.id} "${snap.title}"\n\n[omitted: total wait output limit reached]`,
          );
          break;
        }
        sections.push(section);
        remainingBytes -= sectionBytes;
      }

      const combined = sections.join("\n\n---\n\n");
      const bounded = truncateHead(combined, {
        maxBytes: WAIT_OUTPUT_MAX_BYTES - 128,
        maxLines: DEFAULT_MAX_LINES,
      });
      const text = bounded.truncated
        ? `${bounded.content}\n\n[wait output truncated at the total output limit]`
        : bounded.content;
      return {
        content: [{ type: "text", text }],
        details: {
          results: ids.map((id) => {
            const snap = manager.view.get(id);
            return {
              id,
              title: snap?.title,
              status: snap?.status,
              deliveryId: snap ? subagentDeliveryId(snap) : undefined,
            };
          }),
        },
      };
    },
  });

  pi.registerTool({
    name: "subagent_cancel",
    label: "Cancel Subagents",
    description: SUBAGENT_CANCEL_TOOL_DESCRIPTION,
    parameters: Type.Object({
      ids: Type.Array(Type.String(), {
        description: SUBAGENT_CANCEL_PARAMETER_DESCRIPTIONS.ids,
      }),
    }),
    async execute(_toolCallId, params, signal) {
      const manager = await getManager();
      const ids = [...new Set(params.ids)];
      if (ids.length === 0)
        throw new Error("Provide at least one subagent id.");

      const known = manager.view
        .list()
        .filter(isModelVisible)
        .map((snap) => snap.id);
      const unknown = ids.filter((id) => {
        const snap = manager.view.get(id);
        return !snap || !isModelVisible(snap);
      });
      if (unknown.length > 0) {
        throw new Error(
          `Unknown subagent id(s): ${unknown.join(", ")}. Known: ${known.join(", ") || "none"}.`,
        );
      }

      const report = await runTool(getRuntime(), manager.cancel(ids), {
        signal,
        interruptMessage: "Subagent cancellation aborted.",
      });

      const lines = report.map((entry) =>
        entry.cancelled
          ? `Cancelled ${entry.id} "${entry.title}".`
          : `${entry.id} "${entry.title}" was already ${entry.status}.`,
      );

      return {
        content: [{ type: "text", text: lines.join("\n") }],
        details: {
          results: report.map((entry) => {
            const snap = manager.view.get(entry.id);
            return {
              id: entry.id,
              title: entry.title,
              status: entry.status,
              deliveryId: snap ? subagentDeliveryId(snap) : undefined,
            };
          }),
        },
      };
    },
  });

  pi.registerTool({
    name: "subagent_check",
    label: "Check Subagent",
    description: SUBAGENT_CHECK_TOOL_DESCRIPTION,
    parameters: Type.Object({
      id: Type.String({
        description: SUBAGENT_CHECK_PARAMETER_DESCRIPTIONS.id,
      }),
    }),
    async execute(_toolCallId, params) {
      const manager = await getManager();
      const snap = manager.view.get(params.id);
      if (!snap || !isModelVisible(snap)) {
        const known = manager.view
          .list()
          .filter(isModelVisible)
          .map((s) => s.id);
        throw new Error(
          `Unknown subagent id "${params.id}". Known: ${known.join(", ") || "none"}.`,
        );
      }

      let text = `${describeSubagent(snap)}\nTurns: ${snap.turns}`;
      if (snap.errorText) text += `\nError: ${snap.errorText}`;

      const output = latestText(snap);
      if (output) {
        const preview = truncateHead(output, { maxBytes: 2048, maxLines: 20 });
        text += `\n\nLatest output:\n${preview.content}`;
        if (preview.truncated) text += "\n[...]";
      } else if (snap.status === "running") {
        text += "\n\n(no text output yet)";
      }

      return {
        content: [{ type: "text", text }],
        details: { id: snap.id, status: snap.status, turns: snap.turns },
      };
    },
  });

  pi.registerTool({
    name: "subagent_list",
    label: "List Subagents",
    description: SUBAGENT_LIST_TOOL_DESCRIPTION,
    parameters: Type.Object({}),
    async execute() {
      const manager = await getManager();
      const subs = manager.view.list().filter(isModelVisible);
      const text =
        subs.length === 0
          ? "No subagents."
          : subs.map((snap) => describeSubagent(snap)).join("\n");
      return {
        content: [{ type: "text", text }],
        details: {
          subagents: subs.map((snap) => ({
            id: snap.id,
            title: snap.title,
            harness: snap.backend,
            status: snap.status,
          })),
        },
      };
    },
  });

  // --- Result message rendering ------------------------------------------

  pi.registerMessageRenderer(
    "subagent-result",
    (message, { expanded }, theme) => {
      const details = (message.details ?? {}) as {
        id?: string;
        title?: string;
        status?: string;
      };
      const failed = details.status === "error";
      const icon = failed ? theme.fg("error", "x") : theme.fg("success", "■");
      const header =
        `${icon} ` +
        theme.fg("accent", theme.bold(`subagent ${details.id ?? "?"}`)) +
        theme.fg(
          "muted",
          ` · ${details.title ?? ""} · ${failed ? "failed" : "finished"}`,
        );

      const content =
        typeof message.content === "string" ? message.content : "";
      // Remove only the summary line. The following Error line (when present)
      // is part of the actual result and must remain visible.
      const body = content.split("\n").slice(1).join("\n").trim();

      if (expanded) {
        const md = new Markdown(`${body}`, 0, 0, getMarkdownTheme());
        const container = new Text(header, 0, 0);
        return {
          render: (width: number) => [
            ...container.render(width),
            ...md.render(width),
          ],
          invalidate: () => {
            container.invalidate();
            md.invalidate();
          },
        };
      }

      const previewLines = body.split("\n").slice(0, 8);
      let text = header;
      for (const line of previewLines)
        text += `\n${theme.fg("toolOutput", line)}`;
      if (body.split("\n").length > 8)
        text += `\n${theme.fg("dim", "... (ctrl+o to expand)")}`;
      return new Text(text, 0, 0);
    },
  );

  pi.registerEntryRenderer<BtwResultData>(
    "btw-result",
    (entry, { expanded }, theme) => {
      const data = entry.data;
      const failed = data?.status === "error";
      const icon = failed ? theme.fg("error", "x") : theme.fg("success", "■");
      const header =
        `${icon} ` +
        theme.fg("accent", theme.bold(`by the way · ${data?.title ?? "?"}`)) +
        theme.fg(
          "muted",
          ` · ${failed ? "failed" : "answered"} · ${data?.id ?? "?"}`,
        );
      const body = [
        data?.errorText ? `Error: ${data.errorText}` : "",
        data?.answer ?? "(no answer)",
      ]
        .filter(Boolean)
        .join("\n\n");

      if (expanded) {
        const md = new Markdown(body, 0, 0, getMarkdownTheme());
        const container = new Text(header, 0, 0);
        return {
          render: (width: number) => [
            ...container.render(width),
            ...md.render(width),
          ],
          invalidate: () => {
            container.invalidate();
            md.invalidate();
          },
        };
      }

      const lines = body.split("\n");
      let text = header;
      for (const line of lines.slice(0, 8))
        text += `\n${theme.fg("toolOutput", line)}`;
      if (lines.length > 8)
        text += `\n${theme.fg("dim", "... (ctrl+o to expand)")}`;
      return new Text(text, 0, 0);
    },
  );

  // --- Commands -----------------------------------------------------------

  const runByTheWay = async (rawArgs: string, ctx: ExtensionCommandContext) => {
    if (ctx.mode !== "tui") {
      if (ctx.hasUI)
        ctx.ui.notify("by the way is only available in the TUI", "error");
      return;
    }

    let prompt = rawArgs.trim();
    if (!prompt) {
      const input = await ctx.ui.input("by the way", "Ask a one-off question…");
      prompt = input?.trim() ?? "";
      if (!prompt) return;
    }

    const manager = await getManager();
    let snap: SubagentSnapshot;
    try {
      snap = await runTool(
        getRuntime(),
        manager.spawn(
          "pi",
          {
            origin: "btw",
            prompt,
            title: deriveBtwTitle(prompt),
            cwd: ctx.cwd,
            parent: {
              parentCwd: ctx.cwd,
              projectTrusted: ctx.isProjectTrusted(),
              inheritedModel: ctx.model
                ? { provider: ctx.model.provider, id: ctx.model.id }
                : undefined,
              inheritedThinkingLevel: pi.getThinkingLevel(),
              modelRegistry: ctx.modelRegistry,
            },
          },
          (ready) => {
            if (!runStore) {
              throw new Error("Subagent recovery ledger is unavailable.");
            }
            runStore.register(ready, {});
            pi.appendEntry("subagent-run", {
              id: ready.id,
              harness: ready.backend,
              title: ready.title,
              cwd: ready.cwd,
              nativeSessionId: ready.meta.nativeSessionId,
              sessionFilePath: ready.meta.sessionFilePath,
            });
          },
        ),
      );
    } catch (error) {
      ctx.ui.notify(
        error instanceof Error ? error.message : String(error),
        "error",
      );
      return;
    }

    if (herdrPaneMode === "auto") await openHerdrPane(snap.id, true);
    await openSubagentTakeover(ctx, manager.view, snap.id, {
      badge: "by the way",
    });
  };

  pi.registerCommand("btw", {
    description:
      "Ask a one-off side question while the main agent keeps working",
    handler: runByTheWay,
  });

  pi.registerCommand("subagent-resume", {
    description: "Resume a recovered subagent conversation",
    handler: async (rawArgs, ctx) => {
      const manager = await getManager();
      let id = rawArgs.trim().split(/\s+/, 1)[0] ?? "";
      if (!id && ctx.hasUI) {
        const choices = manager.view
          .list()
          .filter((snap) => snap.status === "recoverable")
          .map((snap) => `${snap.id} · ${snap.title}`);
        if (choices.length === 0) {
          ctx.ui.notify("No recoverable subagents.", "info");
          return;
        }
        const selected = await ctx.ui.select(
          "Resume which subagent?",
          choices,
        );
        id = selected?.split(" · ", 1)[0] ?? "";
      }
      if (!id) return;
      const snap = manager.view.get(id);
      const record = runStore?.get(id);
      if (!snap || !record) {
        if (ctx.hasUI) ctx.ui.notify(`Unknown recovered subagent "${id}".`, "error");
        return;
      }
      if (snap.status === "running") {
        if (ctx.hasUI) ctx.ui.notify(`${id} is already running.`, "error");
        return;
      }
      try {
        await runTool(
          getRuntime(),
          manager.resume(
            id,
            recoveryTask(record, ctx),
            defaultRecoveryPrompt(record),
          ),
        );
        if (ctx.hasUI) ctx.ui.notify(`Resumed ${id} · ${snap.title}`, "info");
      } catch (error) {
        if (ctx.hasUI) {
          ctx.ui.notify(
            error instanceof Error ? error.message : String(error),
            "error",
          );
        }
      }
    },
  });

  pi.registerCommand("subagents", {
    description: "List, inspect, take over, or mirror subagents in Herdr panes",
    handler: async (rawArgs, ctx) => {
      if (ctx.mode !== "tui") {
        if (ctx.hasUI)
          ctx.ui.notify(
            "Subagent takeover is only available in the TUI",
            "error",
          );
        return;
      }

      const args = rawArgs.trim().split(/\s+/).filter(Boolean);
      const manager = await getManager();

      if (args[0] === "panes") {
        const requested = args[1];
        if (!requested || requested === "status") {
          const open = herdrControllerPromise
            ? (await herdrControllerPromise).listOpen().length
            : 0;
          ctx.ui.notify(
            `Herdr subagent panes: ${herdrPaneMode} (${open} open)`,
            "info",
          );
          return;
        }
        if (!(["off", "manual", "auto"] as const).includes(requested as HerdrPaneMode)) {
          ctx.ui.notify("Usage: /subagents panes off|manual|auto|status", "error");
          return;
        }
        if (requested === "auto" && !isInsideHerdr()) {
          ctx.ui.notify("This Pi session is not running inside Herdr.", "error");
          return;
        }
        herdrPaneMode = requested as HerdrPaneMode;
        if (herdrPaneMode === "off") {
          await closeHerdrController();
        } else if (herdrPaneMode === "auto") {
          for (const snap of manager.view.list().filter((snap) => snap.status === "running")) {
            await openHerdrPane(snap.id, true);
          }
        }
        ctx.ui.notify(`Herdr subagent panes set to ${herdrPaneMode}`, "info");
        return;
      }

      if (args[0] === "pane") {
        const action = args[1] === "hide" ? "hide" : "show";
        const target = action === "hide" ? args[2] : args[1];
        if (!target) {
          ctx.ui.notify(
            "Usage: /subagents pane <id|all> or /subagents pane hide <id|all>",
            "error",
          );
          return;
        }
        if (action === "hide") {
          if (!herdrControllerPromise) return;
          const controller = await herdrControllerPromise;
          const ids =
            target === "all" ? controller.listOpen().map((entry) => entry.id) : [target];
          for (const id of ids) await controller.close(id);
          return;
        }
        if (herdrPaneMode === "off") {
          ctx.ui.notify(
            "Herdr subagent panes are off; run /subagents panes manual first.",
            "error",
          );
          return;
        }
        const ids =
          target === "all"
            ? manager.view
                .list()
                .filter((snap) => snap.status === "running")
                .map((snap) => snap.id)
            : [target];
        for (const id of ids) await openHerdrPane(id, true);
        return;
      }

      if (args.length > 0) {
        ctx.ui.notify(
          "Usage: /subagents [panes off|manual|auto|status | pane <id|all> | pane hide <id|all>]",
          "error",
        );
        return;
      }

      if (manager.view.size() === 0) {
        ctx.ui.notify(
          "No subagents yet. The agent spawns them with subagent_spawn.",
          "info",
        );
        return;
      }
      await openSubagentPicker(ctx, manager.view);
    },
  });
}
