---
name: subagents
description: Delegate self-contained work to isolated Pi subagents. Use when the user requests subagents or when parallel research, implementation, or review would materially help.
---

# Subagents

Each subagent is a headless Pi session with its own context window. It cannot see the parent conversation, ask the user, or spawn subagents or workflows. Give every child a self-contained prompt with paths, constraints, and the expected report.

## Pi-Only Dispatch

Always call `subagent_spawn` with `harness: "pi"`. Do not dispatch subagent work through Claude Code or Codex CLI harnesses.

Pi inherits the parent model, thinking level, tools, and configuration when `model` or `reasoning_effort` is omitted. For predictable cost and role separation, normally set both explicitly. Inherit only when matching the parent's configuration is intentional.

Do not use models from the Anthropic provider even if one appears in the model list. Pi can use any other model shown by `pi --list-models`; specify overrides as `provider/model-id` because a bare model id only works when unambiguous.

## Model and Effort Routing

Choose the least expensive configuration likely to succeed, but route by task class before optimizing cost. Current benchmark evidence places Luna and Sol, rather than Terra, on the GPT-5.6 intelligence-versus-cost Pareto frontier. Use Luna for bounded non-UI work and Sol wherever broad judgment, design quality, or architectural coherence matters. Do not route to Terra by default; use it only for deliberate evaluation or when local experience demonstrates a task-specific advantage.

| Role or task | Pi model | Default effort |
| --- | --- | --- |
| Repository reconnaissance, file discovery, documentation lookup, summarization, log/test triage, and simple mechanical non-UI changes | `openai-codex/gpt-5.6-luna` | `low` |
| Normal targeted non-UI implementation, debugging, refactoring, test writing, and focused investigation | `openai-codex/gpt-5.6-luna` | `medium` |
| Any UI/frontend implementation, styling, layout, interaction, accessibility, visual review, or UX work | `openai-codex/gpt-5.6-sol` | `high` |
| Complex codebase architecture, system design, cross-cutting boundaries, major migrations, or planning that determines implementation structure | `openai-codex/gpt-5.6-sol` | `high` |
| Final review or judging, security/correctness-critical analysis, and problems that resisted Luna | `openai-codex/gpt-5.6-sol` | `high` |
| Targeted implementation from an existing concrete Sol plan | `openai-codex/gpt-5.6-luna` | `high`; use `xhigh` or `max` only when justified |

“Any UI work” is an explicit quality-first exception to cost optimization, including apparently small visual changes. Complex architecture work must start with Sol rather than asking Luna to discover the architecture at high effort. Sol may plan, implement, review, or judge these task classes as appropriate.

Use high-effort Luna only for targeted execution after Sol has produced a concrete plan. The plan should identify intended boundaries and invariants, relevant files or components, ordered implementation steps, compatibility constraints, acceptance criteria, and validation. Include that plan verbatim or by exact file path in the Luna prompt. Tell Luna not to redesign the approach silently: if repository evidence conflicts with the plan, it should stop that part and report the mismatch for Sol or the parent to resolve.

A Sol judge should resolve specific disagreements or make a decision against explicit criteria, not merely repeat other agents' summaries.

Set effort from uncertainty and consequence, not task length:

- `low`: bounded, well-specified, low-risk work with obvious validation.
- `medium`: routine coding that requires several steps or local reasoning; this is the default worker setting.
- `high`: Sol UI/architecture/review work, or targeted Luna execution from a concrete Sol plan.
- `xhigh`: Sol escalation for subtle state/concurrency bugs, major architecture, or security-sensitive work; Luna only for unusually difficult targeted execution from a Sol plan.
- `max`: deliberate use for a critical Sol task, or exceptionally difficult targeted Luna execution from a Sol plan, where the added latency and token use are justified; never use routinely.
- Avoid `off` for coding work. In the currently available GPT-5.6 models, `minimal` maps to the provider's `low`, so prefer `low` for clarity.

Do not escalate an unplanned Luna task above `medium`. When routine work becomes ambiguous, architectural, cross-cutting, or UI-related, switch to Sol for planning or execution. Return to Luna at `high` or above only when Sol has reduced the work to a targeted plan. Escalate when a worker reports unresolved uncertainty, cannot validate its result, encounters repeated failures, finds materially larger scope than expected, or reveals higher risk than initially classified. Do not escalate merely because a lower-cost agent produced a concise answer.

## Delegation Patterns

Use the smallest useful topology:

- Small, low-risk non-UI task: one Luna `low` worker; no automatic review.
- Routine targeted non-UI task: one Luna `medium` worker; validate in the parent when practical.
- Any UI task: one Sol `high` worker, adding a separate reviewer only when risk warrants it.
- Complex architecture or important design choice: one Sol `high` planner or worker; use a second Sol judge only when genuine alternatives or high consequences justify it.
- Difficult but targetable implementation: one Sol `high` planner, then one Luna `high` worker executing that plan, followed by a focused Sol `high` conformance review.
- High-risk planned change: one Luna `high` or `xhigh` worker executing the Sol plan, followed by one Sol `high` reviewer.

Prefer one worker with clear ownership over multiple agents making overlapping edits. Parallelize only independent work. Reviewers and judges should normally be read-only: ask them to inspect the current files and diff, cite concrete evidence with file/line references, rank findings by severity, and state whether validation is sufficient. They should not edit unless explicitly assigned a follow-up fix.

Every worker prompt should include the objective, relevant paths, constraints, edit ownership, required validation commands, and expected final report. Every reviewer prompt should include the review criteria and explicitly request missing tests, edge cases, regression risks, and invalid assumptions. Tell all agents to inspect the current workspace rather than trusting summaries of its state.

## Spawn and Manage

Call `subagent_spawn` with a complete `prompt`, short `name`, `harness: "pi"`, and optional `working_dir`, `model`, and `reasoning_effort`. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs, including runs recovered with their parent session.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `subagent_resume({ id, prompt? })`: explicitly continue a recovered native Pi conversation. Recovered work is never replayed automatically because its prior tools may already have caused side effects.
- `/subagent-resume [id]`: let the user explicitly resume a recovered run.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. Run metadata, native session handles, terminal results, and delivery receipts are persisted privately under the Pi agent state directory and restored only for the owning parent session. After spawning, continue useful parent work instead of immediately waiting.
