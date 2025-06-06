return {
	"coder/claudecode.nvim",
	config = true,
	keys = {
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{ "<leader>ao", "<cmd>ClaudeCodeOpen<cr>", desc = "Open Claude" },
		{ "<leader>ax", "<cmd>ClaudeCodeClose<cr>", desc = "Close Claude" },
	},
	opts = {
		terminal = {
			provider = "snacks",
		},
	},
}
