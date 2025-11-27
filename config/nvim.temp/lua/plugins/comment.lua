return {
	{ "echasnovski/mini.nvim", version = false },
	{
		"echasnovski/mini.comment",
		version = false,
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			require("ts_context_commentstring").setup({
				enable_autocmd = false, -- Disable autocmd to avoid conflicts with MiniComment
			})
		end,
	},
}
