local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
	"n",
	"K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
	function()
		vim.cmd.RustLsp({ "hover", "actions" })
	end,
	{ silent = true, buffer = bufnr }
)
vim.keymap.set("n", "<leader>cw", function()
	vim.cmd.RustLsp("codeAction")
end, { desc = "Code Action", buffer = bufnr })
vim.keymap.set("n", "<leader>rd", function()
	vim.cmd.RustLsp("debuggables")
end, { desc = "Rust Debuggables", buffer = bufnr })
