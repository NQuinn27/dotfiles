-- Navigate split windows with Ctrl+h/j/k/l.
vim.keymap.set("n", "<c-k>", "<cmd>wincmd k<CR>", { desc = "Focus upper window" })
vim.keymap.set("n", "<c-j>", "<cmd>wincmd j<CR>", { desc = "Focus lower window" })
vim.keymap.set("n", "<c-h>", "<cmd>wincmd h<CR>", { desc = "Focus left window" })
vim.keymap.set("n", "<c-l>", "<cmd>wincmd l<CR>", { desc = "Focus right window" })
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
vim.keymap.set("n", "<esc>", "<cmd>noh<CR>", { desc = "Clear search highlights" })

-- [[ Core options ]]
vim.opt.guicursor = ""
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"
vim.opt.hlsearch = true
vim.opt.mouse = "a"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.winborder = "rounded"
vim.opt.completeopt = "menuone,noselect"

-- Don't auto-insert comment leaders when using `o`/`O`.
vim.opt.formatoptions:remove("o")
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("FormatOptions", { clear = true }),
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove("o")
	end,
})

-- Highlight yanked text briefly.
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.filetype.add({
	extension = {
		mdx = "mdx",
	},
})
