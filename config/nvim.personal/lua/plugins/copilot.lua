return {
	{
		"github/copilot.vim",
		config = function()
			vim.g.copilot_no_tab_map = true
			vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
		end,
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		build = "make tiktoken",
		opts = {
			debug = true, -- Enable debugging
			window = {
				width = 0.35,
			},
			-- See Configuration section for rest
		}, -- See Commands section for default commands if you want to lazy load on them
		keys = {
			{ "<leader>aa", ":CopilotChat<CR>", desc = "Open CopilotChat" },
			{ "<leader>ac", ":CopilotChatClose<CR>", desc = "Close CopilotChat" },
		},
	},
}
