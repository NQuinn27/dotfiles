return {
	"saghen/blink.cmp",
	dependencies = {
		{ "rafamadriz/friendly-snippets" },
		{
			"saghen/blink.compat",
			optional = false,
			version = "*",
		},
	},
	version = "*",
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "default" },
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		sources = {
			default = {
				"lsp",
				"path",
				"snippets",
				"buffer",
				"avante_commands",
				"avante_mentions",
				"avante_files",
			},
			per_filetype = {
				codecompanion = { "codecompanion" },
			},
			providers = {
				avante_commands = {
					name = "avante_commands",
					module = "blink.compat.source",
					score_offset = 90, -- show at a higher priority than lsp
					opts = {},
				},
				avante_files = {
					name = "avante_files",
					module = "blink.compat.source",
					score_offset = 100, -- show at a higher priority than lsp
					opts = {},
				},
				avante_mentions = {
					name = "avante_mentions",
					module = "blink.compat.source",
					score_offset = 1000, -- show at a higher priority than lsp
					opts = {},
				},
			},
		},
	},
	opts_extend = { "sources.default" },
	signature = { enabled = true },
}
