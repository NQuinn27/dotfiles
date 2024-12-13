-- which-key helps you remember key bindings by showing a popup
-- with the active keybindings of the command you started typing.
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		plugins = { spelling = true },
		defaults = {},
		spec = {
			mode = { "n", "v" },
			{ "g", group = "+goto" },
			{ "gs", group = "+surround" },
			{ "z", group = "+fold" },
			{ "]", group = "+next" },
			{ "[", group = "+prev" },
			{ "<leader><tab>", group = "tabs" },
			{ "<leader>b", group = "+buffer" },
			{ "<leader>c", group = "+code" },
			{ "<leader>f", group = "+file/find" },
			{ "<leader>g", group = "+git" },
			{ "<leader>gh", group = "+hunks" },
			{ "<leader>q", group = "+quit/session" },
			{ "<leader>s", group = "+search" },
			{ "<leader>u", group = "+ui" },
			{ "<leader>w", group = "+windows" },
			{ "<leader>x", group = "+diagnostics/quickfix" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Keymaps (which-key)",
		},
		{
			"<c-w><space>",
			function()
				require("which-key").show({ keys = "<c-w>", loop = true })
			end,
			desc = "Window Hydra Mode (which-key)",
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add(opts.defaults)
	end,
}
