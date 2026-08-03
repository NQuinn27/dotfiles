import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;
type EffortLevel = (typeof LEVELS)[number];

function supportedLevels(ctx: ExtensionCommandContext): EffortLevel[] {
	const model = ctx.model;
	if (!model?.reasoning) return ["off"];

	const levels: EffortLevel[] = ["off", "minimal", "low", "medium", "high"];
	if (model.thinkingLevelMap?.xhigh !== undefined) levels.push("xhigh");
	return levels;
}

export default function effortExtension(pi: ExtensionAPI) {
	pi.registerCommand("effort", {
		description: "Set model effort for this session (off, minimal, low, medium, high, xhigh)",
		getArgumentCompletions: (prefix) => {
			const normalized = prefix.trim().toLowerCase();
			const items = [...LEVELS, "max"]
				.filter((level) => level.startsWith(normalized))
				.map((level) => ({
					value: level,
					label: level,
					description: level === "max" ? "Alias for xhigh (Claude max effort)" : undefined,
				}));
			return items.length > 0 ? items : null;
		},
		handler: async (args, ctx) => {
			const supported = supportedLevels(ctx);
			let requested = args.trim().toLowerCase();

			if (!requested) {
				const current = pi.getThinkingLevel();
				const choice = await ctx.ui.select(
					`Effort (current: ${current})`,
					supported.map((level) => (level === current ? `${level} (current)` : level)),
				);
				if (!choice) return;
				requested = choice.replace(" (current)", "");
			}

			// pi-claude-bridge maps xhigh to the Claude SDK's max effort.
			if (requested === "max") requested = "xhigh";

			if (!LEVELS.includes(requested as EffortLevel)) {
				ctx.ui.notify(`Unknown effort "${requested}". Use: ${LEVELS.join(", ")}, or max`, "error");
				return;
			}

			if (!supported.includes(requested as EffortLevel)) {
				ctx.ui.notify(
					`Effort "${requested}" is not supported by ${ctx.model?.id ?? "the current model"}. Supported: ${supported.join(", ")}`,
					"error",
				);
				return;
			}

			pi.setThinkingLevel(requested as EffortLevel);
			const applied = pi.getThinkingLevel();
			ctx.ui.notify(`Session effort set to ${applied}`, "info");
		},
	});
}
