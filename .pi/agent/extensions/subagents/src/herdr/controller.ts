import { execFile } from "node:child_process";
import { createHash, randomBytes } from "node:crypto";
import * as fs from "node:fs/promises";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { SubagentSnapshot } from "../domain.ts";
import type { SubagentReadModel } from "../manager.ts";

const COMMAND_TIMEOUT_MS = 5_000;
const VIEWER_HANDSHAKE_TIMEOUT_MS = 3_000;
const MAX_COMMAND_OUTPUT_BYTES = 1024 * 1024;
const MAX_BRIDGE_INPUT_BYTES = 64 * 1024;
const MAX_BRIDGE_PENDING_BYTES = 2 * 1024 * 1024;
const MAX_WIRE_TRANSCRIPT_ITEMS = 96;
const MAX_WIRE_TEXT_LENGTH = 16 * 1024;
const UPDATE_DEBOUNCE_MS = 50;
const MIN_TOTAL_WIDTH = 128;
const PARENT_SPLIT_RATIO = 0.68;

export type HerdrPaneMode = "off" | "manual" | "auto";

export interface HerdrCommandResult {
  readonly stdout: string;
  readonly stderr: string;
  readonly code: number;
}

export type HerdrCommandRunner = (
  args: ReadonlyArray<string>,
) => Promise<HerdrCommandResult>;

export interface HerdrPaneActions {
  send(id: string, text: string): Promise<void>;
  abort(id: string): Promise<void> | void;
}

export interface HerdrPaneControllerOptions {
  readonly parentPaneId: string;
  readonly parentSessionId: string;
  readonly view: SubagentReadModel;
  readonly actions: HerdrPaneActions;
  readonly runCommand?: HerdrCommandRunner;
  readonly viewerPath?: string;
  readonly nodePath?: string;
  readonly themeName?: string;
  readonly themePalette?: Readonly<Record<string, string>>;
  /** Test seam; production waits for the viewer to authenticate. */
  readonly viewerHandshakeTimeoutMs?: number;
}

interface OpenPane {
  readonly id: string;
  paneId: string;
  readonly agentLabel: string;
  readonly token: string;
  readonly unsubscribe: () => void;
  socket?: net.Socket;
  pendingSnapshot?: unknown;
  updateTimer?: ReturnType<typeof setTimeout>;
  lastReportedStatus?: SubagentSnapshot["status"];
  lastMetadataKey?: string;
  reportQueue: Promise<void>;
  reportSeq: number;
  readonly connected: Promise<void>;
  readonly resolveConnected: () => void;
  detached: boolean;
}

interface LayoutPane {
  readonly pane_id?: string;
  readonly rect?: { readonly width?: number; readonly height?: number };
}

interface LayoutResult {
  readonly result?: {
    readonly layout?: {
      readonly zoomed?: boolean;
      readonly panes?: ReadonlyArray<LayoutPane>;
    };
  };
}

function defaultViewerPath() {
  return path.join(path.dirname(fileURLToPath(import.meta.url)), "viewer.mjs");
}

function shellQuote(value: string) {
  return `'${value.replaceAll("'", `'\\''`)}'`;
}

function parseJson(stdout: string): unknown {
  const trimmed = stdout.trim();
  if (!trimmed) throw new Error("Herdr returned no JSON response.");
  return JSON.parse(trimmed);
}

function commandError(args: ReadonlyArray<string>, result: HerdrCommandResult) {
  const detail = result.stderr.trim() || result.stdout.trim() || `exit ${result.code}`;
  const safeArgs = args.map((arg, index) => {
    if (args[index - 1] !== "--env") return arg;
    const equals = arg.indexOf("=");
    return equals >= 0 ? `${arg.slice(0, equals)}=<redacted>` : "<redacted>";
  });
  return new Error(`herdr ${safeArgs.join(" ")} failed: ${detail}`);
}

export const runHerdrCommand: HerdrCommandRunner = (args) =>
  new Promise((resolve, reject) => {
    execFile(
      "herdr",
      [...args],
      {
        timeout: COMMAND_TIMEOUT_MS,
        maxBuffer: MAX_COMMAND_OUTPUT_BYTES,
        encoding: "utf8",
      },
      (error, stdout, stderr) => {
        const code = typeof error?.code === "number" ? error.code : error ? 1 : 0;
        const result = { stdout, stderr, code };
        if (error) reject(commandError(args, result));
        else resolve(result);
      },
    );
  });

function wireText(text: string, maxLength = MAX_WIRE_TEXT_LENGTH) {
  return text.length <= maxLength ? text : `${text.slice(0, maxLength)}\n[…truncated…]`;
}

function wireSnapshot(snap: SubagentSnapshot) {
  const transcript = snap.transcript.slice(-MAX_WIRE_TRANSCRIPT_ITEMS).map((item) => {
    if (item.kind === "user") return { ...item, text: wireText(item.text) };
    if (item.kind === "toolResult") {
      return {
        ...item,
        outputPreview: item.outputPreview
          ? wireText(item.outputPreview, 4_096)
          : undefined,
      };
    }
    return {
      ...item,
      parts: item.parts.map((part) =>
        part.type === "toolCall"
          ? {
              ...part,
              argsPreview: part.argsPreview
                ? wireText(part.argsPreview, 4_096)
                : undefined,
            }
          : { ...part, text: wireText(part.text) },
      ),
    };
  });

  return {
    id: snap.id,
    title: snap.title,
    backend: snap.backend,
    status: snap.status,
    createdAt: snap.createdAt,
    generation: snap.generation,
    settledAt: snap.settledAt,
    errorText: snap.errorText,
    meta: {
      modelLabel: snap.meta.modelLabel,
      contextWindow: snap.meta.contextWindow,
    },
    usage: snap.usage,
    finalText: wireText(snap.finalText, 64 * 1024),
    transcript,
    liveAssistant: snap.liveAssistant
      ? {
          text: wireText(snap.liveAssistant.text, 64 * 1024),
          thinking: wireText(snap.liveAssistant.thinking, 64 * 1024),
        }
      : undefined,
    liveTools: snap.liveTools,
    queued: snap.queued,
  };
}

function paneIdFromSplit(response: unknown) {
  const paneId = (
    response as { result?: { pane?: { pane_id?: unknown } } }
  )?.result?.pane?.pane_id;
  if (typeof paneId !== "string" || !paneId) {
    throw new Error("Herdr pane split returned no pane id.");
  }
  return paneId;
}

function statusForHerdr(status: SubagentSnapshot["status"]) {
  return status === "running" ? "working" : "idle";
}

function safeToken(value: string | undefined, fallback = "?") {
  return (value?.replace(/\s+/g, " ").trim() || fallback).slice(0, 80);
}

export class HerdrPaneController {
  private readonly parentPaneId: string;
  private readonly view: SubagentReadModel;
  private readonly actions: HerdrPaneActions;
  private readonly runCommand: HerdrCommandRunner;
  private readonly viewerPath: string;
  private readonly nodePath: string;
  private readonly ownerHash: string;
  private readonly themeName?: string;
  private readonly themePalette?: Readonly<Record<string, string>>;
  private readonly viewerHandshakeTimeoutMs: number;
  private readonly lifecycleSource: string;
  private readonly metadataSource: string;
  private readonly panes = new Map<string, OpenPane>();
  private readonly sockets = new Set<net.Socket>();
  private server?: net.Server;
  private bridgeDirectory?: string;
  private bridgeAddress?: string;
  private layoutQueue: Promise<void> = Promise.resolve();
  private shuttingDown = false;

  constructor(options: HerdrPaneControllerOptions) {
    this.parentPaneId = options.parentPaneId;
    this.view = options.view;
    this.actions = options.actions;
    this.runCommand = options.runCommand ?? runHerdrCommand;
    this.viewerPath = options.viewerPath ?? defaultViewerPath();
    this.nodePath = options.nodePath ?? process.execPath;
    this.themeName = options.themeName;
    this.themePalette = options.themePalette;
    this.viewerHandshakeTimeoutMs =
      options.viewerHandshakeTimeoutMs ?? VIEWER_HANDSHAKE_TIMEOUT_MS;
    this.ownerHash = createHash("sha256")
      .update(`${options.parentSessionId}:${options.parentPaneId}:${process.pid}`)
      .digest("hex")
      .slice(0, 8);
    this.lifecycleSource = `custom:pi-subagents:${this.ownerHash}`;
    this.metadataSource = `custom:pi-subagents-display:${this.ownerHash}`;
  }

  listOpen() {
    return [...this.panes.values()]
      .filter((entry) => !entry.detached)
      .map((entry) => ({ id: entry.id, paneId: entry.paneId }));
  }

  isOpen(id: string) {
    const pane = this.panes.get(id);
    return pane !== undefined && !pane.detached;
  }

  open(id: string) {
    return this.queueLayout(async () => {
      if (this.shuttingDown) throw new Error("Herdr pane controller is shutting down.");
      if (this.isOpen(id)) return;
      const snap = this.view.get(id);
      if (!snap) throw new Error(`Unknown subagent "${id}".`);

      await this.ensureBridge();
      const owned = [...this.panes.values()].filter((entry) => !entry.detached);
      await Promise.all(owned.map((entry) => this.refreshPaneId(entry)));
      const layout = await this.getLayout();
      if (layout.zoomed) {
        throw new Error("Cannot open a subagent pane while the Herdr tab is zoomed.");
      }

      const targetPaneId =
        owned.length === 0 ? this.parentPaneId : this.tallestOwnedPane(layout.panes, owned);
      const targetRect = layout.panes.find((pane) => pane.pane_id === targetPaneId)?.rect;
      if (owned.length === 0 && (targetRect?.width ?? 0) < MIN_TOTAL_WIDTH) {
        throw new Error(
          `Herdr pane is too narrow to split safely (${targetRect?.width ?? "?"} columns; need ${MIN_TOTAL_WIDTH}).`,
        );
      }

      const direction = owned.length === 0 ? "right" : "down";
      const ratio = owned.length === 0 ? String(PARENT_SPLIT_RATIO) : "0.5";
      const paneToken = randomBytes(24).toString("hex");
      const viewerEnvironment = [
        `PI_SUBAGENT_BRIDGE=${this.bridgeAddress}`,
        `PI_SUBAGENT_TOKEN=${paneToken}`,
        `PI_SUBAGENT_ID=${id}`,
        ...(this.themeName ? [`PI_SUBAGENT_THEME=${this.themeName}`] : []),
        ...(this.themePalette
          ? [
              `PI_SUBAGENT_PALETTE=${Buffer.from(
                JSON.stringify(this.themePalette),
                "utf8",
              ).toString("base64")}`,
            ]
          : []),
      ];
      const splitArgs = [
        "pane",
        "split",
        "--pane",
        targetPaneId,
        "--direction",
        direction,
        "--ratio",
        ratio,
        "--cwd",
        snap.cwd,
        ...viewerEnvironment.flatMap((value) => ["--env", value]),
        "--no-focus",
      ];
      const split = await this.command(splitArgs);
      const paneId = paneIdFromSplit(parseJson(split.stdout));
      const agentLabel = `psa-${this.ownerHash}-${id}`.slice(0, 32);
      const unsubscribe = this.view.subscribeTo(id, () => this.scheduleUpdate(id));
      let resolveConnected = () => {};
      const connected = new Promise<void>((resolve) => {
        resolveConnected = resolve;
      });
      const entry: OpenPane = {
        id,
        paneId,
        agentLabel,
        token: paneToken,
        unsubscribe,
        reportQueue: Promise.resolve(),
        reportSeq: Date.now() * 1000,
        connected,
        resolveConnected,
        detached: false,
      };
      this.panes.set(id, entry);

      try {
        await this.command(["pane", "rename", paneId, `${id} · ${snap.title}`.slice(0, 80)]);
        const launch = `exec ${shellQuote(this.nodePath)} ${shellQuote(this.viewerPath)}`;
        await this.command(["pane", "run", paneId, launch]);
        if (this.viewerHandshakeTimeoutMs > 0) {
          await Promise.race([
            entry.connected,
            new Promise<never>((_resolve, reject) => {
              const timer = setTimeout(
                () => reject(new Error("Herdr subagent viewer did not start.")),
                this.viewerHandshakeTimeoutMs,
              );
              timer.unref?.();
            }),
          ]);
        }
        await this.publishState(entry, this.view.get(id) ?? snap, true);
      } catch (error) {
        entry.unsubscribe();
        this.panes.delete(id);
        await this.commandIgnore(["pane", "close", paneId]);
        throw error;
      }
    }).then(() => this.panes.get(id)?.paneId);
  }

  close(id: string) {
    return this.queueLayout(async () => {
      const entry = this.panes.get(id);
      if (!entry) return;
      await this.refreshPaneId(entry);
      this.forget(entry);
      await this.release(entry);
      await this.commandIgnore(["pane", "close", entry.paneId]);
    });
  }

  async closeAll() {
    this.shuttingDown = true;
    await this.queueLayout(async () => {
      const entries = [...this.panes.values()];
      await Promise.all(
        entries.map(async (entry) => {
          await this.refreshPaneId(entry);
          this.forget(entry);
          await this.release(entry);
          // Disconnected viewers are removed from `panes` by the socket close
          // handler, so every remaining entry is still extension-owned (or is
          // waiting for its first connection after pane creation).
          await this.commandIgnore(["pane", "close", entry.paneId]);
        }),
      );
    });
    await this.stopBridge();
  }

  private queueLayout<T>(operation: () => Promise<T>) {
    const result = this.layoutQueue.then(operation, operation);
    this.layoutQueue = result.then(
      () => undefined,
      () => undefined,
    );
    return result;
  }

  private async command(args: ReadonlyArray<string>) {
    const result = await this.runCommand(args);
    if (result.code !== 0) throw commandError(args, result);
    return result;
  }

  private async commandIgnore(args: ReadonlyArray<string>) {
    try {
      await this.command(args);
      return true;
    } catch {
      // Herdr integration is best-effort and pane/user actions can race us.
      return false;
    }
  }

  private async refreshPaneId(entry: OpenPane) {
    try {
      const result = await this.command(["agent", "get", entry.agentLabel]);
      const paneId = (
        parseJson(result.stdout) as {
          result?: { agent?: { pane_id?: unknown } };
        }
      ).result?.agent?.pane_id;
      if (typeof paneId === "string" && paneId) entry.paneId = paneId;
    } catch {
      // The initial lifecycle report may not exist yet, or the user may have
      // closed the pane. Callers retain the last known id and fail safely.
    }
  }

  private async getLayout() {
    const result = await this.command(["pane", "layout", "--pane", this.parentPaneId]);
    const parsed = parseJson(result.stdout) as LayoutResult;
    const layout = parsed.result?.layout;
    if (!layout || !Array.isArray(layout.panes)) {
      throw new Error("Herdr returned an invalid pane layout.");
    }
    return { zoomed: layout.zoomed === true, panes: layout.panes };
  }

  private tallestOwnedPane(panes: ReadonlyArray<LayoutPane>, owned: ReadonlyArray<OpenPane>) {
    const heights = new Map(
      panes.map((pane) => [pane.pane_id, pane.rect?.height ?? 0] as const),
    );
    return [...owned].sort(
      (a, b) => (heights.get(b.paneId) ?? 0) - (heights.get(a.paneId) ?? 0),
    )[0]?.paneId ?? owned[owned.length - 1]?.paneId ?? this.parentPaneId;
  }

  private scheduleUpdate(id: string) {
    const entry = this.panes.get(id);
    if (!entry || entry.detached || entry.updateTimer) return;
    entry.updateTimer = setTimeout(() => {
      entry.updateTimer = undefined;
      const snap = this.view.get(id);
      if (!snap || entry.detached) return;
      this.sendSnapshot(entry, snap);
      void this.publishState(entry, snap, false);
    }, UPDATE_DEBOUNCE_MS);
  }

  private publishState(entry: OpenPane, snap: SubagentSnapshot, force: boolean) {
    const report = entry.reportQueue.then(() =>
      this.publishStateNow(entry, snap, force),
    );
    entry.reportQueue = report.catch(() => {});
    return report;
  }

  private async publishStateNow(
    entry: OpenPane,
    snap: SubagentSnapshot,
    force: boolean,
  ) {
    if (entry.detached) return;
    if (force || entry.lastReportedStatus !== snap.status) {
      const report = () =>
        this.commandIgnore([
          "pane",
          "report-agent",
          entry.paneId,
          "--source",
          this.lifecycleSource,
          "--agent",
          entry.agentLabel,
          "--state",
          statusForHerdr(snap.status),
          "--message",
          `${snap.id}: ${snap.title}`.slice(0, 80),
          "--seq",
          String(++entry.reportSeq),
        ]);
      const previousPaneId = entry.paneId;
      let reported = await report();
      if (!reported) {
        await this.refreshPaneId(entry);
        if (entry.paneId !== previousPaneId) reported = await report();
      }
      if (reported) entry.lastReportedStatus = snap.status;
    }

    const statusLabel = snap.status === "error" ? "failed" : snap.status;
    const metadataKey = `${snap.meta.modelLabel ?? ""}:${statusLabel}`;
    if (!force && entry.lastMetadataKey === metadataKey) return;
    const report = () =>
      this.commandIgnore([
        "pane",
        "report-metadata",
        entry.paneId,
        "--source",
        this.metadataSource,
        "--agent",
        entry.agentLabel,
        "--title",
        `${snap.id} · ${snap.title}`.slice(0, 80),
        "--display-agent",
        `${snap.backend} · ${snap.id}`.slice(0, 80),
        "--token",
        `subagent=${safeToken(snap.id)}`,
        "--token",
        `backend=${safeToken(snap.backend)}`,
        "--token",
        `model=${safeToken(snap.meta.modelLabel)}`,
        "--token",
        `status=${statusLabel}`,
        "--seq",
        String(++entry.reportSeq),
      ]);
    const previousPaneId = entry.paneId;
    let reported = await report();
    if (!reported) {
      await this.refreshPaneId(entry);
      if (entry.paneId !== previousPaneId) reported = await report();
    }
    if (reported) entry.lastMetadataKey = metadataKey;
  }

  private async release(entry: OpenPane) {
    await this.commandIgnore([
      "pane",
      "release-agent",
      entry.paneId,
      "--source",
      this.lifecycleSource,
      "--agent",
      entry.agentLabel,
      "--seq",
      String(++entry.reportSeq),
    ]);
  }

  private forget(entry: OpenPane) {
    entry.detached = true;
    if (entry.updateTimer) clearTimeout(entry.updateTimer);
    entry.updateTimer = undefined;
    entry.unsubscribe();
    entry.socket?.destroy();
    this.panes.delete(entry.id);
  }

  private async ensureBridge() {
    if (this.server) return;
    if (process.platform === "win32") {
      this.bridgeAddress = `\\\\.\\pipe\\pi-subagents-${process.pid}-${randomBytes(6).toString("hex")}`;
    } else {
      this.bridgeDirectory = await fs.mkdtemp(path.join(os.tmpdir(), "pi-subagents-"));
      this.bridgeAddress = path.join(this.bridgeDirectory, "bridge.sock");
    }

    const server = net.createServer((socket) => this.acceptViewer(socket));
    this.server = server;
    try {
      await new Promise<void>((resolve, reject) => {
        const onError = (error: Error) => {
          server.off("listening", onListening);
          reject(error);
        };
        const onListening = () => {
          server.off("error", onError);
          resolve();
        };
        server.once("error", onError);
        server.once("listening", onListening);
        server.listen(this.bridgeAddress);
      });
      // A late server error must not become an uncaught process error. New
      // pane opens will still fail their viewer handshake if the bridge dies.
      server.on("error", () => {});
    } catch (error) {
      this.server = undefined;
      server.close();
      if (this.bridgeDirectory) {
        await fs.rm(this.bridgeDirectory, { recursive: true, force: true });
      }
      this.bridgeDirectory = undefined;
      this.bridgeAddress = undefined;
      throw error;
    }
  }

  private acceptViewer(socket: net.Socket) {
    this.sockets.add(socket);
    socket.setEncoding("utf8");
    let authenticated: OpenPane | undefined;
    let input = "";
    let actionQueue = Promise.resolve();
    const authTimer = setTimeout(() => socket.destroy(), 5_000);
    authTimer.unref?.();

    socket.on("data", (chunk: string) => {
      input += chunk;
      if (input.length > MAX_BRIDGE_INPUT_BYTES) {
        socket.destroy();
        return;
      }
      while (true) {
        const newline = input.indexOf("\n");
        if (newline < 0) break;
        const line = input.slice(0, newline);
        input = input.slice(newline + 1);
        let parsed: unknown;
        try {
          parsed = JSON.parse(line);
        } catch {
          socket.destroy();
          return;
        }
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
          socket.destroy();
          return;
        }
        const message = parsed as Record<string, unknown>;

        if (!authenticated) {
          const id = typeof message.id === "string" ? message.id : "";
          const candidate = this.panes.get(id);
          if (
            message.type !== "hello" ||
            message.token !== candidate?.token ||
            !candidate ||
            candidate.detached
          ) {
            socket.destroy();
            return;
          }
          authenticated = candidate;
          clearTimeout(authTimer);
          candidate.socket?.destroy();
          candidate.socket = socket;
          candidate.resolveConnected();
          const snap = this.view.get(id);
          if (snap) this.sendSnapshot(candidate, snap);
          continue;
        }

        const entry = authenticated;
        actionQueue = actionQueue.then(
          () => this.handleViewerMessage(entry, socket, message),
          () => this.handleViewerMessage(entry, socket, message),
        );
      }
    });

    socket.on("drain", () => {
      if (!authenticated?.pendingSnapshot || authenticated.socket !== socket) return;
      const pending = authenticated.pendingSnapshot;
      authenticated.pendingSnapshot = undefined;
      if (!this.send(socket, pending)) authenticated.pendingSnapshot = pending;
    });

    socket.on("close", () => {
      clearTimeout(authTimer);
      this.sockets.delete(socket);
      if (authenticated?.socket !== socket) return;
      authenticated.socket = undefined;
      if (this.shuttingDown || authenticated.detached) return;
      // A closed viewer connection means the user closed the pane or the
      // viewer exited. Detach visualization only; never cancel the subagent
      // and never later close a potentially repurposed shell pane.
      authenticated.detached = true;
      authenticated.unsubscribe();
      if (authenticated.updateTimer) clearTimeout(authenticated.updateTimer);
      this.panes.delete(authenticated.id);
      void this.release(authenticated);
    });
    socket.on("error", () => {});
  }

  private async handleViewerMessage(
    entry: OpenPane,
    socket: net.Socket,
    message: Record<string, unknown>,
  ) {
    const requestId = typeof message.requestId === "string" ? message.requestId : undefined;
    let detach = false;
    try {
      if (entry.detached || entry.socket !== socket || socket.destroyed) {
        throw new Error("Viewer connection is no longer active.");
      }
      if (message.type === "send") {
        const text = typeof message.text === "string" ? message.text.trim() : "";
        if (!text) throw new Error("Message is empty.");
        await this.actions.send(entry.id, text);
      } else if (message.type === "abort") {
        await this.actions.abort(entry.id);
      } else if (message.type === "detach") {
        detach = true;
        entry.detached = true;
        entry.unsubscribe();
        if (entry.updateTimer) clearTimeout(entry.updateTimer);
        this.panes.delete(entry.id);
        await this.release(entry);
      } else {
        throw new Error("Unknown viewer action.");
      }
      if (requestId)
        this.send(socket, { type: "response", requestId, ok: true }, true);
      if (detach) socket.end();
    } catch (error) {
      if (requestId) {
        this.send(socket, {
          type: "response",
          requestId,
          ok: false,
          error: error instanceof Error ? error.message : String(error),
        }, true);
      }
    }
  }

  private sendSnapshot(entry: OpenPane, snap: SubagentSnapshot) {
    const value = { type: "snapshot", snapshot: wireSnapshot(snap) };
    if (this.send(entry.socket, value)) entry.pendingSnapshot = undefined;
    else entry.pendingSnapshot = value;
  }

  private send(socket: net.Socket | undefined, value: unknown, force = false) {
    if (!socket || socket.destroyed) return false;
    if (!force && socket.writableLength > MAX_BRIDGE_PENDING_BYTES) return false;
    socket.write(`${JSON.stringify(value)}\n`);
    return true;
  }

  private async stopBridge() {
    const server = this.server;
    this.server = undefined;
    for (const socket of this.sockets) socket.destroy();
    this.sockets.clear();
    if (server) {
      await new Promise<void>((resolve) => server.close(() => resolve()));
    }
    if (this.bridgeDirectory) {
      await fs.rm(this.bridgeDirectory, { recursive: true, force: true });
    }
    this.bridgeDirectory = undefined;
    this.bridgeAddress = undefined;
  }
}
