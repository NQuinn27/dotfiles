---
name: subagents
description: Delegate self-contained work to isolated Pi, Claude Code, or Codex agents. Use when the user requests subagents or when parallel research, implementation, or review would materially help.
---

# Subagents

Each subagent is headless, has its own context window, cannot see the parent conversation, cannot ask the user, and cannot spawn subagents or workflows. Give every child a self-contained prompt with paths, constraints, and the expected report.

## Model Routing Ethos

Treat these as strong defaults, not rigid dispatch rules. Use judgment based on scope, uncertainty, and cost; an explicit user choice always wins.

Apply the defaults in this order:

1. **UI work → Claude Code with `opus` (Opus 4.8), `high`.** This takes priority for frontend implementation, layout, styling, interaction design, visual polish, and UI review. For mixed tasks, give the UI portion to Opus.
2. **Very difficult non-UI problems → Claude Code with `fable`, `high`.** Reserve Fable for genuinely hard, ambiguous, or wide-ranging reasoning such as architecture, deep debugging, and complex planning; do not spend it on routine work.
3. **Targeted work → Codex with `gpt-5.6-sol`, `high`.** Prefer this for bounded implementation, investigation, bug fixes, refactors, tests, and focused code review.
4. **Otherwise → Pi/inherited model.** Use Pi when inheriting the parent's model, tools, and configuration is useful or no specialist clearly fits.

### Adversarial Review

For difficult, high-risk, or uncertain work, consider a focused review by the opposite model family. This is an escalation option, not a mandatory second agent for every task.

- Work produced by Opus (or another Claude model) → review with Codex `gpt-5.6-sol`, `high`.
- Work produced by Codex `gpt-5.6-sol` → review with Claude Code `opus`, `high`.
- Ask the reviewer to challenge assumptions, identify failure modes, inspect edge cases, and propose missing validation rather than simply repeating the implementation.
- Prefer one strong worker plus one targeted reviewer over multiple agents doing the same work independently.

## Pi Harness

**Harness:** `pi`
**Prompt nicknames:** “pi”, “pi agent”, “pi subagent”
**Best default:** Use when inheriting the parent model and environment is valuable and no specialist in the routing guidance above is a better fit. It inherits the parent model and thinking level when `model` or `reasoning_effort` is omitted.

Do not use models from the Anthropic provider even if one appears in the model list.

Pi can use any model shown by `pi --list-models`. Prefer `provider/model-id`; a bare model id only works when unambiguous. Common picks in this environment:

| Model                            | Recommended effort |
| -------------------------------- | ------------------ |
| inherited parent model (default) | inherited          |
| `openai-codex/gpt-5.6-sol`       | `high`             |
| `openai-codex/gpt-5.6-terra`     | `high`             |

**Thinking budgets:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. These map directly to pi thinking levels.

## Claude Code Harness

**Harness:** `claude`
**Prompt nicknames:** “claude”, “Claude Code”, “claude agent”, “claude subagent”, "cc"
**Best default:** Follow the routing guidance above: Opus 4.8 for UI work; Fable for exceptionally difficult non-UI work.

| Model hint | Model                    | Recommended effort |
| ---------- | ------------------------ | ------------------ |
| `opus`     | latest Claude Opus (4.8) | `high`             |
| `fable`    | latest Claude Fable      | `high`             |

**Thinking budgets:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. The extension maps these to Claude thinking-token budgets: 0, 1,024, 4,096, 10,000, 16,000, 32,000, and 63,999 tokens respectively.

Requires Claude Code to be installed and authenticated.

## Codex Harness

**Harness:** `codex`
**Prompt nicknames:** “codex”, “Codex CLI”, “codex agent”, “codex subagent”
**Best default:** `gpt-5.6-sol` with `high` effort for targeted coding work and adversarial review of Claude-produced work. Do not use anything other than Sol unless the user specifically asks for it.

| Model           | Recommended effort |
| --------------- | ------------------ |
| `gpt-5.6-sol`   | `high`             |
| `gpt-5.6-terra` | `high`             |
| `gpt-5.6-luna`  | `high`             |

**Thinking budgets accepted by the extension:** `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`. Codex maps these to the nearest effort supported by the selected model; `off`/`minimal` become `minimal`, while `max` becomes the highest extension-supported Codex effort.

Requires the Codex CLI to be installed and authenticated. Codex subagents only start in Pi-trusted working directories because the headless backend runs without approval prompts.

## Spawn and Manage

Call `subagent_spawn` with a complete `prompt`, short `name`, chosen `harness`, and optional `working_dir`, `model`, and `reasoning_effort`. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs, including runs recovered with their parent session.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `subagent_resume({ id, prompt? })`: explicitly continue a recovered native Pi, Claude Code, or Codex conversation. Recovered work is never replayed automatically because its prior tools may already have caused side effects.
- `/subagent-resume [id]`: let the user explicitly resume a recovered run.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. Run metadata, native session handles, terminal results, and delivery receipts are persisted privately under the Pi agent state directory and restored only for the owning parent session. After spawning, continue useful parent work instead of immediately waiting.
