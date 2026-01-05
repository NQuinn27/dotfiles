return {
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = false,
			italic_comments = true,
			underline_links = true,
			disable_nvimtree_bg = false,
		},
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				styles = {
					bold = true,
					italic = true,
					transparency = true,
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "mocha",
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
		"f-person/auto-dark-mode.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			update_interval = 1000,
			set_dark_mode = function()
				vim.o.background = "dark"
				vim.cmd("colorscheme gruvbox")
				-- require("vscode").load("dark")
				-- -- Comments more prominent
				-- vim.api.nvim_set_hl(0, "Normal", { bg = "#141415" })
				vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "#1E2021" })
				-- vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#D7BA7D", bg = "none", nocombine = true })
				-- vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = "#181818" })
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1E2021" })
				-- vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "#181818" })
				-- vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#181818" })
			end,
			set_light_mode = function()
				vim.o.background = "light"
				vim.cmd("colorscheme gruvbox")
			end,
		},
	},
}
