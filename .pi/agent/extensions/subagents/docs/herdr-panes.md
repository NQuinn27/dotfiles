# Herdr subagent panes

When the parent Pi session runs inside Herdr, the extension can mirror its
headless subagents into terminal panes. The real Pi/Claude/Codex session stays
owned by `SubagentManager`; each pane runs a small authenticated viewer over the
normalized `SubagentSnapshot` stream.

## Commands

- `/subagents panes status` — show the current mode and open pane count.
- `/subagents panes manual` — default; panes open only when requested.
- `/subagents panes auto` — open panes for running subagents and future spawns.
- `/subagents panes off` — close extension-owned viewers and disable auto-open.
- `/subagents pane <id>` — open one viewer.
- `/subagents pane all` — open viewers for all currently running subagents.
- `/subagents pane hide <id|all>` — close viewer panes without cancelling runs.

The first viewer splits to the right of the parent pane without taking focus.
Further viewers split the tallest extension-owned viewer downward. Unsafe
narrow or zoomed layouts are left unchanged.

## Viewer controls

- `↑` / `↓` — scroll the transcript by five lines.
- `Page Up` / `Page Down` — scroll by one page.
- `Home` / `End` — jump to the oldest/latest transcript lines.
- `Ctrl+R` — toggle between the full transcript and final-result view.
- `Enter` — send/steer the subagent and return to the live transcript.
- `Ctrl+X` — abort the current run.
- `Ctrl+D` (or `Ctrl+C`) — close/detach the viewer without cancelling the run.

The viewer keeps an internal scroll offset because its live full-screen redraw
cannot use Herdr's host scrollback reliably. New output does not pull a viewer
back to the bottom while it is reading older lines.

The parent Pi theme palette is passed to each viewer. Assistant and final-result
text use Pi's Markdown renderer, while tool calls/results use a compact Pi-like
layout. The mirror cannot reproduce every native tool renderer because its
normalized event stream intentionally contains bounded previews rather than the
backend's complete native TUI state.

Closing a pane never cancels its subagent. Session shutdown closes only viewers
still owned by the extension.

## Security and lifecycle

The bridge uses a random token and a per-session local Unix socket (or Windows
named pipe). Prompts and tokens are not included in pane command lines. Viewer
updates are bounded and backpressure-aware.

Headless Claude and Codex processes receive an environment with `HERDR_*`
removed so native integrations cannot report their hidden sessions against the
parent pane. In-process Pi children omit the Herdr control skill for the same
reason.
