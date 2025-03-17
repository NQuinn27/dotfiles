return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "frappe",
			background = {
				dark = "frappe",
				light = "latte",
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
	-- {
	-- "folke/tokyonight.nvim",
	-- lazy = false,
	-- priority = 1000,
	-- config = function()
	-- 	require("tokyonight").setup({
	-- 		light_style = "day",
	-- 	})
	-- 	vim.cmd.colorscheme("tokyonight-night")
	-- end,
	-- },
}
