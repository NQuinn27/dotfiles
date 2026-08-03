import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const buildContinuationPrompt = (sessionFile: string | undefined, compactionEntryId: string) => {
  const fallback = sessionFile
    ? `If the compacted context is genuinely insufficient, inspect the active branch in ${JSON.stringify(sessionFile)} by following parentId links to compaction entry ${JSON.stringify(compactionEntryId)}.`
    : "This session is ephemeral, so no older persisted history is available if the compacted context is insufficient.";

  return `Compaction has completed. Resume the existing task instead of waiting for another user prompt.

Use the compaction summary and retained context to recover the goal, constraints, decisions, completed work, unresolved issues, and intended next action. Reconcile them with the current repository state, treating the worktree as authoritative for file contents. ${fallback}

Briefly state the context you recovered, then immediately perform the next unfinished step. Do not stop after the recap or ask the user to repeat context unless it is genuinely unavailable or ambiguous.`;
};

export default function continueAfterCompaction(pi: ExtensionAPI) {
  const pendingTimers = new Set<ReturnType<typeof setTimeout>>();

  pi.on("session_compact", (event, ctx) => {
    // Overflow recovery already retries the interrupted turn automatically.
    if (event.willRetry) return;

    const prompt = buildContinuationPrompt(
      ctx.sessionManager.getSessionFile(),
      event.compactionEntry.id,
    );

    const timer = setTimeout(() => {
      pendingTimers.delete(timer);
      pi.sendUserMessage(prompt, { deliverAs: "followUp" });
    }, 0);

    pendingTimers.add(timer);
  });

  pi.on("session_shutdown", () => {
    for (const timer of pendingTimers) clearTimeout(timer);
    pendingTimers.clear();
  });
}
