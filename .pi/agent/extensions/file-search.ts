import { mkdtemp, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  truncateHead,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const EXEC_TIMEOUT_MS = 30_000;
const FD_DEFAULT_LIMIT = 1_000;
const FD_MAX_LIMIT = 10_000;
const RG_DEFAULT_LIMIT = 100;
const RG_MAX_LIMIT = 1_000;

function clamp(value: number, minimum: number, maximum: number) {
  return Math.min(maximum, Math.max(minimum, Math.floor(value)));
}

function normalizePath(raw: string | undefined) {
  if (raw === undefined) return undefined;
  let value = raw.trim();
  if (value.startsWith("@")) value = value.slice(1);
  if (value === "~") return homedir();
  if (value.startsWith("~/")) return join(homedir(), value.slice(2));
  return value || undefined;
}

async function formatOutput(output: string, prefix: string) {
  const text = output.replace(/\n+$/, "");
  const truncation = truncateHead(text, {
    maxBytes: DEFAULT_MAX_BYTES,
    maxLines: DEFAULT_MAX_LINES,
  });
  if (!truncation.truncated) {
    return { text, truncated: false, fullOutputPath: undefined };
  }

  const directory = await mkdtemp(join(tmpdir(), prefix));
  const fullOutputPath = join(directory, "output.txt");
  await writeFile(fullOutputPath, text, "utf8");
  return {
    text:
      `${truncation.content}\n\n` +
      `[Output truncated: ${truncation.outputLines} of ${truncation.totalLines} lines ` +
      `(${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). ` +
      `Full output saved to: ${fullOutputPath}]`,
    truncated: true,
    fullOutputPath,
  };
}

function commandError(tool: string, code: number, stderr: string) {
  const detail = stderr.trim();
  return new Error(
    `${tool} exited with code ${code}${detail ? `: ${detail}` : ""}`,
  );
}

export default function fileSearch(pi: ExtensionAPI) {
  pi.registerTool({
    name: "fd",
    label: "Find Files",
    description:
      "Find files and directories by name with fd. Respects .gitignore by default. Output is limited to 2000 lines or 50KB, with complete truncated output saved to a temporary file.",
    promptSnippet:
      "Find files and directories by name with fd (fast and gitignore-aware)",
    promptGuidelines: [
      "Use fd as the primary tool for discovering files and directories by name, extension, or glob.",
      "Use rg instead of fd when searching file contents.",
      "Use bash for complex pipelines or post-processing.",
    ],
    parameters: Type.Object({
      pattern: Type.Optional(
        Type.String({
          description:
            "Name regex, or a glob when glob is true. Omit to list everything.",
        }),
      ),
      path: Type.Optional(
        Type.String({
          description:
            "Directory to search; defaults to the current working directory.",
        }),
      ),
      type: Type.Optional(
        StringEnum(["file", "directory", "symlink"] as const),
      ),
      extension: Type.Optional(
        Type.String({ description: "File extension such as ts or md." }),
      ),
      glob: Type.Optional(
        Type.Boolean({
          description: "Treat pattern as a glob instead of a regex.",
        }),
      ),
      hidden: Type.Optional(
        Type.Boolean({ description: "Include hidden entries." }),
      ),
      max_depth: Type.Optional(Type.Integer({ minimum: 1, maximum: 64 })),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: FD_MAX_LIMIT })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = ["--color=never"];
      if (params.hidden) args.push("--hidden");
      if (params.glob) args.push("--glob");
      if (params.type) {
        const typeFlag = { file: "f", directory: "d", symlink: "l" }[
          params.type
        ];
        args.push("--type", typeFlag);
      }
      if (params.extension)
        args.push("--extension", params.extension.replace(/^\.+/, ""));
      if (params.max_depth !== undefined)
        args.push("--max-depth", String(params.max_depth));
      args.push(
        "--max-results",
        String(clamp(params.limit ?? FD_DEFAULT_LIMIT, 1, FD_MAX_LIMIT)),
      );
      args.push("--", params.pattern ?? "");
      const path = normalizePath(params.path);
      if (path) args.push(path);

      const result = await pi.exec("fd", args, {
        cwd: ctx.cwd,
        signal,
        timeout: EXEC_TIMEOUT_MS,
      });
      if (result.killed) throw new Error("fd was cancelled or timed out");
      if (result.code !== 0)
        throw commandError("fd", result.code, result.stderr);
      if (!result.stdout.trim()) {
        return {
          content: [{ type: "text" as const, text: "No files found" }],
          details: { matches: 0 },
        };
      }
      const formatted = await formatOutput(result.stdout, "pi-fd-");
      const matches = result.stdout.replace(/\n+$/, "").split("\n").length;
      return {
        content: [{ type: "text" as const, text: formatted.text }],
        details: {
          matches,
          truncated: formatted.truncated,
          fullOutputPath: formatted.fullOutputPath,
        },
      };
    },
  });

  pi.registerTool({
    name: "rg",
    label: "Search Content",
    description:
      "Search file contents with ripgrep. Uses smart-case and respects .gitignore by default. Output is limited to 2000 lines or 50KB, with complete truncated output saved to a temporary file.",
    promptSnippet:
      "Search file contents with ripgrep (fast regex content search)",
    promptGuidelines: [
      "Use rg as the primary tool for searching file contents.",
      "Use fd instead of rg when looking for files by name.",
      "Set fixed_strings when searching for literal code containing regex metacharacters.",
      "Use bash for complex pipelines or post-processing.",
    ],
    parameters: Type.Object({
      pattern: Type.String({
        description:
          "Regex to search for, or literal text when fixed_strings is true.",
      }),
      path: Type.Optional(
        Type.String({
          description:
            "File or directory to search; defaults to the current working directory.",
        }),
      ),
      glob: Type.Optional(
        Type.String({ description: "Only search files matching this glob." }),
      ),
      file_type: Type.Optional(
        Type.String({
          description: "Ripgrep file type such as ts, js, py, or rust.",
        }),
      ),
      case_sensitive: Type.Optional(
        Type.Boolean({
          description: "Force case sensitivity on or off; omit for smart-case.",
        }),
      ),
      fixed_strings: Type.Optional(
        Type.Boolean({ description: "Treat pattern as literal text." }),
      ),
      hidden: Type.Optional(
        Type.Boolean({ description: "Search hidden files and directories." }),
      ),
      context: Type.Optional(Type.Integer({ minimum: 0, maximum: 20 })),
      limit: Type.Optional(
        Type.Integer({
          minimum: 1,
          maximum: RG_MAX_LIMIT,
          description: "Maximum matches per file.",
        }),
      ),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = [
        "--line-number",
        "--color=never",
        "--no-heading",
        "--with-filename",
      ];
      if (params.case_sensitive === true) args.push("--case-sensitive");
      else if (params.case_sensitive === false) args.push("--ignore-case");
      else args.push("--smart-case");
      if (params.fixed_strings) args.push("--fixed-strings");
      if (params.hidden) args.push("--hidden");
      if (params.context !== undefined)
        args.push("--context", String(params.context));
      if (params.glob) args.push("--glob", params.glob);
      if (params.file_type) args.push("--type", params.file_type);
      args.push(
        "--max-count",
        String(clamp(params.limit ?? RG_DEFAULT_LIMIT, 1, RG_MAX_LIMIT)),
      );
      args.push("--", params.pattern);
      const path = normalizePath(params.path);
      if (path) args.push(path);

      const result = await pi.exec("rg", args, {
        cwd: ctx.cwd,
        signal,
        timeout: EXEC_TIMEOUT_MS,
      });
      if (result.killed) throw new Error("rg was cancelled or timed out");
      if (result.code === 1) {
        return {
          content: [{ type: "text" as const, text: "No matches found" }],
          details: { lines: 0 },
        };
      }
      if (result.code !== 0)
        throw commandError("rg", result.code, result.stderr);
      const formatted = await formatOutput(result.stdout, "pi-rg-");
      const lines = result.stdout.replace(/\n+$/, "").split("\n").length;
      return {
        content: [{ type: "text" as const, text: formatted.text }],
        details: {
          lines,
          truncated: formatted.truncated,
          fullOutputPath: formatted.fullOutputPath,
        },
      };
    },
  });
}
