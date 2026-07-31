vim.opt_local.conceallevel = 0
vim.opt_local.textwidth = 120 -- Set text width to 120 characters
vim.opt_local.wrap = true -- Enable line wrapping
vim.opt_local.linebreak = true -- Wrap at word boundaries
vim.keymap.set(
	"n",
	"<leader>mdp",
	vim.cmd.MarkdownPreview,
	{ desc = "Markdown preview", noremap = true, silent = true }
)
