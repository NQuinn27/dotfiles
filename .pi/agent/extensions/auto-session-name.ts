import { basename } from "node:path";
import { completeSimple } from "@earendil-works/pi-ai/compat";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";

const ENTRY_TYPE = "auto-session-name";
const STATUS_KEY = "auto-session-name";
const PREFERRED_MODEL = {
  provider: "openai-codex",
  id: "gpt-5.6-luna",
} as const;
const MAX_TITLE_LENGTH = 60;
const MAX_USER_MESSAGE_LENGTH = 1_500;
const MAX_ASSISTANT_TURN_LENGTH = 1_000;
const MAX_TRANSCRIPT_LENGTH = 10_000;

const SYSTEM_PROMPT = `Name a coding-agent session from its opening conversation.

Return only one concise plain-text title.
- Use 3-8 words and at most ${MAX_TITLE_LENGTH} characters.
- Describe the concrete project, problem, or intended outcome.
- Prefer specific nouns and verbs from the conversation.
- Do not use quotes, markdown, labels, emoji, or ending punctuation.
- Avoid generic titles such as "Coding help", "New session", or "General discussion".`;

type NamingStage = 1 | 2;

type AutoNameState = {
  readonly version: 1;
  readonly stage: NamingStage;
  readonly name: string;
};

type MessageEntry = Extract<SessionEntry, { type: "message" }>;

function textFromContent(content: unknown) {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (block): block is { type: "text"; text: string } =>
        typeof block === "object" &&
        block !== null &&
        "type" in block &&
        block.type === "text" &&
        "text" in block &&
        typeof block.text === "string",
    )
    .map((block) => block.text)
    .join("\n");
}

function truncate(text: string, maxLength: number) {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;
  return `${normalized.slice(0, maxLength - 1).trimEnd()}…`;
}

export function countUserMessages(entries: readonly SessionEntry[]) {
  return entries.filter(
    (entry): entry is MessageEntry =>
      entry.type === "message" && entry.message.role === "user",
  ).length;
}

export function buildOpeningTranscript(
  entries: readonly SessionEntry[],
  maxUserMessages: number,
) {
  const turns: Array<{ user: string; assistant: string[] }> = [];

  for (const entry of entries) {
    if (entry.type !== "message") continue;

    const { message } = entry;
    if (message.role === "user") {
      if (turns.length >= maxUserMessages) break;
      const user =
        truncate(textFromContent(message.content), MAX_USER_MESSAGE_LENGTH) ||
        "[Image attachment]";
      turns.push({ user, assistant: [] });
      continue;
    }

    if (message.role !== "assistant" || turns.length === 0) continue;
    const text = textFromContent(message.content).trim();
    if (text) turns.at(-1)?.assistant.push(text);
  }

  const lines = turns.flatMap((turn) => {
    const assistant = truncate(
      turn.assistant.join("\n"),
      MAX_ASSISTANT_TURN_LENGTH,
    );
    return assistant
      ? [`User: ${turn.user}`, `Assistant: ${assistant}`]
      : [`User: ${turn.user}`];
  });
  return truncate(lines.join("\n\n"), MAX_TRANSCRIPT_LENGTH);
}

export function cleanGeneratedTitle(value: string) {
  let title = value
    // Strip ANSI and OSC terminal control sequences before using model output in a title.
    // eslint-disable-next-line no-control-regex
    .replace(/\x1b(?:\][^\x07]*(?:\x07|\x1b\\)|\[[0-?]*[ -/]*[@-~])/g, "")
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/^```(?:text)?\s*|\s*```$/gi, "")
    .replace(/^\s*(?:title|session(?: title| name)?)\s*:\s*/i, "")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/^["'“‘`]+|["'”’`]+$/g, "")
    .replace(/[.!?,;:]+$/g, "")
    .trim();

  if (title.length > MAX_TITLE_LENGTH) {
    const candidate = title.slice(0, MAX_TITLE_LENGTH + 1);
    const wordBoundary = candidate.lastIndexOf(" ");
    title = candidate
      .slice(0, wordBoundary >= 24 ? wordBoundary : MAX_TITLE_LENGTH)
      .trimEnd();
  }

  return title;
}

function isAutoNameState(value: unknown): value is AutoNameState {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Partial<AutoNameState>;
  return (
    candidate.version === 1 &&
    (candidate.stage === 1 || candidate.stage === 2) &&
    typeof candidate.name === "string" &&
    candidate.name.length > 0
  );
}

export function restoreOwnership(
  entries: readonly SessionEntry[],
  currentName: string | undefined,
) {
  let autoState: AutoNameState | undefined;
  let autoStateIndex = -1;
  let sessionInfoIndex = -1;

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];
    if (sessionInfoIndex < 0 && entry?.type === "session_info") {
      sessionInfoIndex = index;
    }
    if (
      autoStateIndex < 0 &&
      entry?.type === "custom" &&
      entry.customType === ENTRY_TYPE &&
      isAutoNameState(entry.data)
    ) {
      autoState = entry.data;
      autoStateIndex = index;
    }
    if (autoStateIndex >= 0 && sessionInfoIndex >= 0) break;
  }

  const automationOwnsName =
    autoState !== undefined &&
    autoStateIndex > sessionInfoIndex &&
    autoState.name === currentName;
  return {
    autoState: automationOwnsName ? autoState : undefined,
    manualOverride: currentName !== undefined && !automationOwnsName,
  };
}

function fallbackTitle(cwd: string) {
  return basename(cwd) || cwd;
}

export function buildHerdrTitleCommands(
  name: string | undefined,
  cwd: string,
  sequence: number,
  environment: NodeJS.ProcessEnv = process.env,
) {
  const paneId = environment.HERDR_PANE_ID;
  if (environment.HERDR_ENV !== "1" || !paneId) return [];

  const titleArgs = name ? ["--title", name] : ["--clear-title"];
  const commands = [
    [
      "pane",
      "report-metadata",
      paneId,
      "--source",
      "pi-auto-session-name",
      "--applies-to-source",
      "herdr:pi",
      ...titleArgs,
      "--seq",
      String(sequence),
    ],
  ];

  // Metadata titles decorate the pane/agent, but Herdr's sidebar displays the
  // tab label. Rename the containing tab explicitly so both surfaces agree.
  const tabId = environment.HERDR_TAB_ID;
  if (tabId)
    commands.push(["tab", "rename", tabId, name ?? fallbackTitle(cwd)]);
  return commands;
}

function updateTerminalTitle(name: string | undefined, ctx: ExtensionContext) {
  if (ctx.mode !== "tui") return;
  ctx.ui.setTitle(`pi · ${name ?? fallbackTitle(ctx.cwd)}`);
}

async function resolveNamingModel(ctx: ExtensionContext) {
  const preferred = ctx.modelRegistry.find(
    PREFERRED_MODEL.provider,
    PREFERRED_MODEL.id,
  );
  const availableModels = [preferred, ctx.model].filter(
    (model): model is NonNullable<typeof model> => model !== undefined,
  );
  const candidates = availableModels.filter(
    (model, index, models) =>
      models.findIndex(
        (candidate) =>
          candidate.provider === model.provider && candidate.id === model.id,
      ) === index,
  );

  let authError: string | undefined;
  for (const model of candidates) {
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (auth.ok) return { model, auth };
    authError = auth.error;
  }

  if (authError) throw new Error(authError);
  throw new Error("No model is selected");
}

async function generateTitle(
  transcript: string,
  ctx: ExtensionContext,
  signal: AbortSignal,
) {
  const { model, auth } = await resolveNamingModel(ctx);
  const response = await completeSimple(
    model,
    {
      systemPrompt: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: `Project directory: ${fallbackTitle(ctx.cwd)}\n\nOpening conversation:\n${transcript}`,
          timestamp: Date.now(),
        },
      ],
    },
    {
      apiKey: auth.apiKey,
      env: auth.env,
      headers: auth.headers,
      maxRetries: 1,
      maxTokens: 100,
      signal,
      timeoutMs: 30_000,
    },
  );

  if (
    response.stopReason === "error" ||
    response.stopReason === "aborted" ||
    response.stopReason === "length"
  ) {
    throw new Error(
      response.errorMessage ??
        (response.stopReason === "length"
          ? "The naming model reached its output limit"
          : "The naming model request failed"),
    );
  }

  const title = cleanGeneratedTitle(
    response.content
      .filter((block) => block.type === "text")
      .map((block) => block.text)
      .join("\n"),
  );
  if (!title) throw new Error("The naming model returned an empty title");
  return title;
}

export default function autoSessionNameExtension(pi: ExtensionAPI) {
  let sessionActive = false;
  let sessionId: string | undefined;
  let autoState: AutoNameState | undefined;
  let manualOverride = false;
  let pendingAutomaticNames: string[] = [];
  let activeController: AbortController | undefined;
  let activeTask: Promise<void> | undefined;
  let reevaluateAfterTask = false;
  let startupTitleTimer: ReturnType<typeof setTimeout> | undefined;
  let failureNotified = false;
  let herdrFailureNotified = false;
  let herdrSequence = Date.now() * 1_000;
  let herdrUpdateQueue = Promise.resolve();

  const updateDisplayedTitle = (
    name: string | undefined,
    ctx: ExtensionContext,
  ) => {
    updateTerminalTitle(name, ctx);
    herdrSequence += 1;
    const commands = buildHerdrTitleCommands(name, ctx.cwd, herdrSequence);
    if (commands.length === 0) return;

    // Serialize updates so a slower old rename cannot overwrite a newer title.
    herdrUpdateQueue = herdrUpdateQueue
      .then(async () => {
        for (const args of commands) {
          const result = await pi.exec("herdr", args, { timeout: 2_000 });
          if (result.code !== 0) {
            throw new Error(
              result.stderr.trim() || `herdr exited with code ${result.code}`,
            );
          }
        }
        herdrFailureNotified = false;
      })
      .catch((error: unknown) => {
        if (!sessionActive || herdrFailureNotified) return;
        const detail = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Could not update the Herdr title: ${detail}`, "warning");
        herdrFailureNotified = true;
      });
  };

  const automationCanReplaceCurrentName = () => {
    if (manualOverride) return false;
    const currentName = pi.getSessionName();
    return autoState
      ? currentName === autoState.name
      : currentName === undefined;
  };

  const runNaming = (
    stage: NamingStage,
    transcript: string,
    ctx: ExtensionContext,
    options: { readonly notify: boolean },
  ) => {
    if (
      !sessionActive ||
      activeTask ||
      !transcript ||
      !automationCanReplaceCurrentName()
    ) {
      return false;
    }

    const expectedSessionId = sessionId;
    const expectedName = pi.getSessionName();
    const controller = new AbortController();
    activeController = controller;
    ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("muted", "✦ naming session…"));

    const task = (async () => {
      try {
        const name = await generateTitle(transcript, ctx, controller.signal);
        if (
          controller.signal.aborted ||
          !sessionActive ||
          sessionId !== expectedSessionId ||
          manualOverride ||
          pi.getSessionName() !== expectedName
        ) {
          return;
        }

        pendingAutomaticNames.push(name);
        pi.setSessionName(name);
        autoState = { version: 1, stage, name };
        pi.appendEntry(ENTRY_TYPE, autoState);
        updateDisplayedTitle(name, ctx);
        failureNotified = false;
        if (options.notify) ctx.ui.notify(`Session named: ${name}`, "info");
      } catch (error) {
        if (controller.signal.aborted || !sessionActive) return;
        const detail = error instanceof Error ? error.message : String(error);
        if (options.notify || !failureNotified) {
          ctx.ui.notify(`Could not name the session: ${detail}`, "warning");
          failureNotified = true;
        }
      }
    })().finally(() => {
      const shouldReevaluate = reevaluateAfterTask;
      reevaluateAfterTask = false;
      if (activeController === controller) activeController = undefined;
      if (activeTask === task) activeTask = undefined;
      ctx.ui.setStatus(STATUS_KEY, undefined);

      if (
        shouldReevaluate &&
        sessionActive &&
        sessionId === expectedSessionId
      ) {
        queueMicrotask(() => maybeNameFromBranch(ctx));
      }
    });

    activeTask = task;
    return true;
  };

  const maybeNameFromBranch = (ctx: ExtensionContext) => {
    if (!sessionActive || autoState?.stage === 2) return false;
    if (activeTask) {
      reevaluateAfterTask = true;
      return false;
    }
    if (!automationCanReplaceCurrentName()) return false;

    const branch = ctx.sessionManager.getBranch();
    const userMessageCount = countUserMessages(branch);
    if (userMessageCount === 0) return false;

    const stage: NamingStage = userMessageCount >= 3 ? 2 : 1;
    if (autoState?.stage === stage) return false;

    const transcript = buildOpeningTranscript(branch, stage === 1 ? 1 : 3);
    return runNaming(stage, transcript, ctx, { notify: false });
  };

  pi.on("session_start", (_event, ctx) => {
    sessionActive = ctx.mode === "tui";
    sessionId = ctx.sessionManager.getSessionId();
    const ownership = restoreOwnership(
      ctx.sessionManager.getEntries(),
      pi.getSessionName(),
    );
    autoState = ownership.autoState;
    manualOverride = ownership.manualOverride;
    pendingAutomaticNames = [];
    reevaluateAfterTask = false;
    failureNotified = false;
    herdrFailureNotified = false;

    if (startupTitleTimer) clearTimeout(startupTitleTimer);
    if (!sessionActive) return;
    startupTitleTimer = setTimeout(() => {
      startupTitleTimer = undefined;
      if (sessionActive && sessionId === ctx.sessionManager.getSessionId()) {
        updateDisplayedTitle(pi.getSessionName(), ctx);
      }
    }, 0);
  });

  pi.on("session_info_changed", (event, ctx) => {
    const automaticIndex =
      event.name === undefined ? -1 : pendingAutomaticNames.indexOf(event.name);
    if (automaticIndex >= 0) {
      pendingAutomaticNames.splice(automaticIndex, 1);
    } else {
      manualOverride = true;
    }
    updateDisplayedTitle(pi.getSessionName(), ctx);
  });

  pi.on("agent_settled", (_event, ctx) => {
    maybeNameFromBranch(ctx);
  });

  pi.on("session_shutdown", async () => {
    sessionActive = false;
    reevaluateAfterTask = false;
    if (startupTitleTimer) clearTimeout(startupTitleTimer);
    startupTitleTimer = undefined;
    activeController?.abort();
    await activeTask?.catch(() => undefined);
    await herdrUpdateQueue;
    activeController = undefined;
    activeTask = undefined;
  });

  pi.registerCommand("auto-name", {
    description:
      "Generate or refresh the session name from its opening messages",
    handler: async (_args, ctx) => {
      if (manualOverride) {
        ctx.ui.notify("The manual session name was preserved", "info");
        return;
      }

      const branch = ctx.sessionManager.getBranch();
      const userMessageCount = countUserMessages(branch);
      if (userMessageCount === 0) {
        ctx.ui.notify("There are no user messages to name yet", "warning");
        return;
      }
      if (activeTask) {
        ctx.ui.notify("A session name is already being generated", "info");
        return;
      }

      const stage: NamingStage = userMessageCount >= 3 ? 2 : 1;
      const transcript = buildOpeningTranscript(branch, stage === 1 ? 1 : 3);
      if (!runNaming(stage, transcript, ctx, { notify: true })) {
        ctx.ui.notify("Could not start session naming", "warning");
        return;
      }
      await activeTask;
    },
  });
}
