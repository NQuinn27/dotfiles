return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "macchiato",
			dim_inactive = {
				enabled = true, -- dims the background color of inactive window
				shade = "dark",
				percentage = 0.15, -- percentage of the shade to apply to the inactive window
			},
			term_colors = true,
		},
	},
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = true,
		opts = {
			terminal_colors = true, -- add neovim terminal colors
			undercurl = true,
			underline = true,
			bold = true,
			italic = {
				strings = true,
				emphasis = true,
				comments = true,
				operators = false,
				folds = true,
			},
			strikethrough = true,
			invert_selection = false,
			invert_signs = false,
			invert_tabline = false,
			inverse = true, -- invert background for search, diffs, statuslines and errors
			contrast = "hard", -- can be "hard", "soft" or empty string
			palette_overrides = {},
			overrides = {},
			dim_inactive = false,
			transparent_mode = false,
		},
	},
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = false,
			italic_comments = true,
			underline_links = true,
			disable_nvimtree_bg = false,
			terminal_colors = true,
		},
		config = function(_, opts)
			require("vscode").setup(opts)
			vim.cmd.colorscheme("vscode")
		end,
	},
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,

		config = function()
			-- Optionally configure and load the colorscheme
			-- directly inside the plugin declaration.
			vim.g.everforest_enable_italic = true
			vim.g.everforest_background = "hard"
		end,
	},
	{
		"f-person/auto-dark-mode.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			update_interval = 1000,
			set_dark_mode = function()
				vim.o.background = "dark"
				vim.cmd.colorscheme("vscode")
			end,
			set_light_mode = function()
				vim.o.background = "light"
				vim.cmd.colorscheme("vscode")
			end,
		},
	},
}
