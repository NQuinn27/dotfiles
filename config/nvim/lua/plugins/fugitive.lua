return {
	"tpope/vim-fugitive",
	keys = {
		{ "<leader>gs", vim.cmd.Git, desc = "Git fugitive" },
		{ "<leader>gb", ":Git blame<CR>", desc = "Git Blame (fugitive)" },
	},
}
