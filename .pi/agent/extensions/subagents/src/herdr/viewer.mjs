#!/usr/bin/env node

import * as net from "node:net";
import {
  getMarkdownTheme,
  initTheme,
} from "@earendil-works/pi-coding-agent";
import {
  Markdown,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";

const address = process.env.PI_SUBAGENT_BRIDGE;
const token = process.env.PI_SUBAGENT_TOKEN;
const id = process.env.PI_SUBAGENT_ID;

if (!address || !token || !id) {
  process.stderr.write("Missing Pi subagent viewer connection details.\n");
  process.exit(1);
}

let inheritedPalette = {};
try {
  inheritedPalette = JSON.parse(
    Buffer.from(process.env.PI_SUBAGENT_PALETTE ?? "", "base64").toString(
      "utf8",
    ),
  );
} catch {
  inheritedPalette = {};
}
try {
  initTheme(process.env.PI_SUBAGENT_THEME || "dark");
} catch {
  initTheme("dark");
}
const markdownTheme = getMarkdownTheme();
const palette = (name, fallback) => inheritedPalette[name] || fallback;
const colors = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  italic: "\x1b[3m",
  accent: palette("accent", "\x1b[36m"),
  border: palette("border", "\x1b[2m"),
  borderAccent: palette("borderAccent", "\x1b[36m"),
  success: palette("success", "\x1b[32m"),
  error: palette("error", "\x1b[31m"),
  warning: palette("warning", "\x1b[33m"),
  muted: palette("muted", "\x1b[2m"),
  dim: palette("dim", "\x1b[2m"),
  text: palette("text", "\x1b[39m"),
  user: palette("userMessageText", "\x1b[36m"),
  toolTitle: palette("toolTitle", "\x1b[35m"),
  toolOutput: palette("toolOutput", "\x1b[2m"),
  thinking: palette("thinkingText", "\x1b[2m"),
};

let snapshot;
let input = "";
let incoming = "";
let requestCounter = 0;
let notice = "connecting…";
let closing = false;
let scrollOffset = 0;
let resultView = false;
const MAX_INPUT_LENGTH = 16 * 1024;
const SCROLL_STEP = 5;

const socket = net.createConnection(address);
socket.setEncoding("utf8");

function send(value) {
  if (!socket.destroyed) socket.write(`${JSON.stringify(value)}\n`);
}

function clean(text) {
  return String(text ?? "")
    // eslint-disable-next-line no-control-regex
    .replace(/[\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[a-zA-Z\d]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-nq-uy=><~]))/g, "")
    .replaceAll("\t", "  ")
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u0008\u000b-\u001f\u007f]/g, "");
}

function wrap(text, width, prefix = "") {
  const available = Math.max(10, width - prefix.length);
  const output = [];
  const sourceLines = clean(text).split("\n");
  for (const source of sourceLines) {
    if (!source) {
      output.push(prefix);
      continue;
    }
    let rest = source;
    let first = true;
    while (rest.length > available) {
      let cut = rest.lastIndexOf(" ", available);
      if (cut < Math.floor(available / 2)) cut = available;
      output.push(`${first ? prefix : " ".repeat(prefix.length)}${rest.slice(0, cut)}`);
      rest = rest.slice(cut).trimStart();
      first = false;
    }
    output.push(`${first ? prefix : " ".repeat(prefix.length)}${rest}`);
  }
  return output;
}

function markdownLines(text, width) {
  if (!clean(text).trim()) return [];
  return new Markdown(clean(text), 0, 0, markdownTheme)
    .render(width)
    .map((line) => truncateToWidth(line, width, ""));
}

function compactToolArguments(value) {
  const text = clean(value).trim();
  if (!text) return "";
  try {
    const parsed = JSON.parse(text);
    if (!parsed || typeof parsed !== "object") return text;
    if (typeof parsed.command === "string") return parsed.command;
    if (typeof parsed.path === "string") return parsed.path;
    return Object.entries(parsed)
      .map(([key, item]) => `${key}=${typeof item === "string" ? item : JSON.stringify(item)}`)
      .join(" ");
  } catch {
    // Codex command events provide a command string rather than JSON.
  }
  const shell = text.match(/^\/bin\/(?:zsh|bash|sh)\s+-lc\s+(['"])([\s\S]*)\1$/);
  return shell?.[2] ?? text;
}

function renderToolCall(part, width) {
  const lines = [
    `${colors.toolTitle}› ${colors.bold}${clean(part.name)}${colors.reset}`,
  ];
  const args = compactToolArguments(part.argsPreview);
  if (args) {
    const isShell = /^(?:shell|bash|command|commandExecution)$/i.test(part.name);
    for (const line of wrap(args, Math.max(10, width - 4))) {
      lines.push(
        `${colors.dim}  ${isShell ? "$ " : ""}${line}${colors.reset}`,
      );
    }
  }
  return lines;
}

function renderToolResult(item, width) {
  const output = clean(item.outputPreview || "(no output)");
  const color = item.isError ? colors.error : colors.toolOutput;
  return wrap(output, Math.max(10, width - 4)).map(
    (line, index) =>
      `${color}  ${index === 0 ? "└ " : "  "}${line}${colors.reset}`,
  );
}

function transcriptLines(snap, width) {
  const lines = [];
  let previousWasToolCall = false;
  for (const item of snap.transcript ?? []) {
    if (item.kind === "toolResult" && previousWasToolCall && lines.at(-1) === "") {
      lines.pop();
    }

    if (item.kind === "user") {
      const wrapped = wrap(item.text, Math.max(10, width - 2));
      lines.push(
        ...wrapped.map(
          (line, index) =>
            `${colors.user}${index === 0 ? "› " : "  "}${line}${colors.reset}`,
        ),
      );
      previousWasToolCall = false;
    } else if (item.kind === "assistant") {
      previousWasToolCall = false;
      for (const part of item.parts ?? []) {
        if (part.type === "text") {
          lines.push(...markdownLines(part.text, width));
        } else if (part.type === "thinking") {
          const text = part.redacted ? "[redacted reasoning]" : part.text;
          for (const line of wrap(text, Math.max(10, width - 2))) {
            lines.push(
              `${colors.thinking}${colors.italic}│ ${line}${colors.reset}`,
            );
          }
        } else if (part.type === "toolCall") {
          lines.push(...renderToolCall(part, width));
          previousWasToolCall = true;
        }
      }
    } else if (item.kind === "toolResult") {
      lines.push(...renderToolResult(item, width));
      previousWasToolCall = false;
    }
    lines.push("");
  }

  const live = snap.liveAssistant;
  if (live?.thinking) {
    for (const line of wrap(live.thinking, Math.max(10, width - 2))) {
      lines.push(`${colors.thinking}${colors.italic}│ ${line}${colors.reset}`);
    }
  }
  if (live?.text) lines.push(...markdownLines(live.text, width));

  for (const tool of snap.liveTools ?? []) {
    lines.push(
      `${colors.toolTitle}› ${colors.bold}${clean(tool.name)}${colors.reset} ${colors.warning}running${colors.reset}`,
    );
    if (tool.outputPreview) {
      lines.push(...renderToolResult({ ...tool, isError: false }, width));
    }
  }
  for (const queued of snap.queued ?? []) {
    for (const line of wrap(queued.text, Math.max(10, width - 4))) {
      lines.push(
        `${colors.warning}  queued ${queued.kind} · ${line}${colors.reset}`,
      );
    }
  }
  while (lines.at(-1) === "") lines.pop();
  return lines;
}

function finalResultText(snap) {
  const finalText = clean(snap.finalText).trim();
  if (finalText) return finalText;
  for (let index = (snap.transcript?.length ?? 0) - 1; index >= 0; index--) {
    const item = snap.transcript[index];
    if (item?.kind !== "assistant") continue;
    const text = (item.parts ?? [])
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n")
      .trim();
    if (text) return text;
  }
  return "(no final result yet)";
}

function resultLines(snap, width) {
  const lines = [
    `${colors.accent}${colors.bold}Final result${colors.reset}`,
    "",
    ...markdownLines(finalResultText(snap), width),
  ];
  if (snap.errorText) {
    lines.unshift(
      `${colors.error}error: ${clean(snap.errorText)}${colors.reset}`,
      "",
    );
  }
  return lines;
}

function viewportHeight() {
  const rows = Math.max(12, process.stdout.rows || 30);
  return Math.max(3, rows - 5);
}

function currentLines(snap = snapshot) {
  if (!snap) return [];
  const columns = Math.max(40, process.stdout.columns || 80);
  return resultView
    ? resultLines(snap, columns)
    : transcriptLines(snap, columns);
}

function maxScrollOffset(lines = currentLines()) {
  return Math.max(0, lines.length - Math.max(1, viewportHeight() - 1));
}

function scrollBy(lines) {
  scrollOffset = Math.min(
    maxScrollOffset(),
    Math.max(0, scrollOffset + lines),
  );
  render();
}

function elapsed(snap) {
  const end = snap.settledAt ?? Date.now();
  const seconds = Math.max(0, Math.round((end - snap.createdAt) / 1000));
  const minutes = Math.floor(seconds / 60);
  return minutes ? `${minutes}m${String(seconds % 60).padStart(2, "0")}s` : `${seconds}s`;
}

function render() {
  const columns = Math.max(40, process.stdout.columns || 80);
  const rows = Math.max(12, process.stdout.rows || 30);
  const border = `${colors.border}${"─".repeat(columns)}${colors.reset}`;
  const output = [];

  if (!snapshot) {
    output.push(
      `${colors.accent}${colors.bold}${id}${colors.reset} ${colors.muted}· ${notice}${colors.reset}`,
      border,
    );
  } else {
    const statusColor =
      snapshot.status === "running" || snapshot.status === "recoverable"
        ? colors.warning
        : snapshot.status === "done"
          ? colors.success
          : colors.error;
    const usage =
      snapshot.usage?.tokens && snapshot.usage?.contextWindow
        ? ` · ${Math.round((snapshot.usage.tokens / snapshot.usage.contextWindow) * 100)}% ctx`
        : "";
    output.push(
      truncateToWidth(
        `${statusColor}■ ${colors.bold}${snapshot.status}${colors.reset} ${colors.muted}· ${clean(snapshot.backend)} · ${clean(snapshot.meta?.modelLabel || "?")} · ${elapsed(snapshot)}${usage}${colors.reset}`,
        columns,
        "",
      ),
      border,
    );

    const bodyHeight = viewportHeight();
    const lines = currentLines(snapshot);
    if (!resultView && snapshot.errorText) {
      lines.push("", `${colors.error}error: ${clean(snapshot.errorText)}${colors.reset}`);
    }
    const indicatorRows = scrollOffset > 0 ? 1 : 0;
    const contentHeight = Math.max(1, bodyHeight - indicatorRows);
    const maximumOffset = Math.max(0, lines.length - contentHeight);
    scrollOffset = Math.min(scrollOffset, maximumOffset);
    const end = Math.max(0, lines.length - scrollOffset);
    const visible = lines.slice(Math.max(0, end - contentHeight), end);
    while (visible.length < contentHeight) visible.push("");
    output.push(...visible);
    if (scrollOffset > 0) {
      output.push(
        truncateToWidth(
          `${colors.dim}… ${scrollOffset} line${scrollOffset === 1 ? "" : "s"} below · ↓/pgdn/end toward latest${colors.reset}`,
          columns,
          "",
        ),
      );
    }
    output.push(border);
  }

  const inputPrefix = `${colors.accent}›${colors.reset} `;
  const inputWidth = Math.max(1, columns - visibleWidth(inputPrefix));
  const visibleInput = truncateToWidth(input, inputWidth, "");
  output.push(
    `${inputPrefix}${visibleInput}`,
    truncateToWidth(
      `${colors.dim}↑↓ scroll · pgup/dn page · home/end · ^R ${resultView ? "transcript" : "result"} · ↵ send · ^X abort · ^D close${notice ? ` · ${notice}` : ""}${colors.reset}`,
      columns,
      "",
    ),
  );
  process.stdout.write(`\x1b[?25l\x1b[2J\x1b[H${output.join("\n")}`);
  const inputColumn = Math.min(columns - 1, 2 + Array.from(input).length);
  process.stdout.write(`\x1b[1A\r\x1b[${inputColumn}C\x1b[?25h`);
}

function request(type, extra = {}) {
  const requestId = `${process.pid}-${++requestCounter}`;
  send({ type, requestId, ...extra });
  notice = type === "send" ? "sending…" : "aborting…";
  render();
}

function detachAndExit(code = 0) {
  if (closing) return;
  closing = true;
  send({ type: "detach" });
  setTimeout(() => {
    socket.destroy();
    cleanup();
    process.exit(code);
  }, 30).unref();
}

function cleanup() {
  try {
    if (process.stdin.isTTY) process.stdin.setRawMode(false);
  } catch {
    // The PTY may already be gone because the pane was closed.
  }
  process.stdout.write("\x1b[?25h\x1b[0m\n");
}

socket.on("connect", () => {
  notice = "";
  send({ type: "hello", id, token });
  render();
});
socket.on("data", (chunk) => {
  incoming += chunk;
  while (true) {
    const newline = incoming.indexOf("\n");
    if (newline < 0) break;
    const line = incoming.slice(0, newline);
    incoming = incoming.slice(newline + 1);
    try {
      const message = JSON.parse(line);
      if (message.type === "snapshot") {
        const oldLineCount = currentLines().length;
        snapshot = message.snapshot;
        const newLineCount = currentLines().length;
        if (scrollOffset > 0) {
          scrollOffset += Math.max(0, newLineCount - oldLineCount);
        }
        notice = "";
      } else if (message.type === "response") {
        notice = message.ok ? "" : `error: ${message.error || "request failed"}`;
      }
      render();
    } catch {
      notice = "invalid bridge response";
      render();
    }
  }
});
socket.on("error", (error) => {
  notice = `bridge error: ${error.message}`;
  render();
});
socket.on("close", () => {
  if (!closing) {
    cleanup();
    process.exit(0);
  }
});

if (process.stdin.isTTY) process.stdin.setRawMode(true);
process.stdin.setEncoding("utf8");
process.stdin.resume();
process.stdin.on("data", (buffer) => {
  // Arrow/page/home/end keys scroll the viewer's own transcript viewport.
  // Herdr host scrollback cannot represent a full-screen live redraw.
  const data = buffer
    .toString("utf8")
    // eslint-disable-next-line no-control-regex
    .replace(/\u001b\[[0-9;?]*[ -/]*[@-~]/g, (sequence) => {
      if (sequence === "\u001b[A") scrollBy(SCROLL_STEP);
      else if (sequence === "\u001b[B") scrollBy(-SCROLL_STEP);
      else if (sequence === "\u001b[5~") scrollBy(viewportHeight() - 1);
      else if (sequence === "\u001b[6~") scrollBy(-(viewportHeight() - 1));
      else if (sequence === "\u001b[H" || sequence === "\u001b[1~") {
        scrollOffset = maxScrollOffset();
        render();
      } else if (sequence === "\u001b[F" || sequence === "\u001b[4~") {
        scrollOffset = 0;
        render();
      }
      return "";
    });
  let changed = false;
  for (const character of data) {
    const code = character.charCodeAt(0);
    if (code === 4 || code === 3) {
      detachAndExit();
      return;
    }
    if (code === 24) {
      request("abort");
      continue;
    }
    if (code === 18) {
      resultView = !resultView;
      scrollOffset = 0;
      render();
      continue;
    }
    if (character === "\r" || character === "\n") {
      const text = input.trim();
      if (text) {
        input = "";
        resultView = false;
        scrollOffset = 0;
        request("send", { text });
      }
      continue;
    }
    if (code === 127 || code === 8) {
      input = Array.from(input).slice(0, -1).join("");
      changed = true;
      continue;
    }
    if (code >= 32 && code !== 127 && input.length < MAX_INPUT_LENGTH) {
      input += character;
      changed = true;
    }
  }
  if (changed) render();
});
process.stdout.on("resize", render);
process.on("SIGTERM", () => detachAndExit());
process.on("SIGHUP", () => detachAndExit());

setInterval(() => {
  if (snapshot?.status === "running") render();
}, 1000).unref();
render();
