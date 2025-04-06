return {
	{
		"olimorris/codecompanion.nvim",
		keys = {
			{ "<leader>aa", "<cmd>CodeCompanionChat<cr>", desc = "Open CodeCompanion Chat" },
			{ "<leader>at", "<cmd>CodeCompanionChat toggle<cr>", desc = "Open CodeCompanion Chat" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "copilot",
					},
					inline = {
						adapter = "copilot",
					},
				},
				adapters = {
					copilot = function()
						return require("codecompanion.adapters").extend("copilot", {
							schema = {
								model = {
									default = "claude-3.7-sonnet",
								},
							},
						})
					end,
				},
				display = {
					chat = {
						window = {
							position = "right",
						},
					},
				},
			})
		end,
	},
	{
		"saghen/blink.cmp",
		opts = {
			sources = {
				per_filetype = {
					codecompanion = { "codecompanion" },
				},
			},
		},
	},
}
