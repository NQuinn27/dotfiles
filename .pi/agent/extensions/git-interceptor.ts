import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const GIT_ENV_PREFIX =
  "export GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true GIT_MERGE_AUTOEDIT=no\n";

// Match git as a command token, including common absolute paths, rather than
// unrelated words that merely contain the substring "git".
const GIT_COMMAND_RE = /(?:^|[\s;&|()])(?:[^\s;&|()]*\/)?git(?=$|[\s;&|()])/m;
const NO_VERIFY_RE = /--no-verify\b/;

const BLOCK_REASON =
  "BLOCKED: --no-verify is not allowed. Fix the failing Git hook or ask the user for help instead of bypassing it.";

export default function gitInterceptor(pi: ExtensionAPI) {
  pi.on("tool_call", (event) => {
    if (!isToolCallEventType("bash", event)) return;
    if (!GIT_COMMAND_RE.test(event.input.command)) return;

    if (NO_VERIFY_RE.test(event.input.command)) {
      return { block: true, reason: BLOCK_REASON };
    }

    event.input.command = GIT_ENV_PREFIX + event.input.command;
  });
}
