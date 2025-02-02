-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keymaps for better default experience
-- See `:help vim.keymap.set()

-- vim.keymap.set("n", "<leader>pv", vim.cmd.Explore)
-- vim.keymap.set("n", "-", vim.cmd.Explore)
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move whole lines up and down
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv")

vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "Q", "<nop")

-- Find and replace for current word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "t<C-n>", vim.cmd.TestNearest, { noremap = true, silent = true })
vim.keymap.set("n", "t<C-f>", vim.cmd.TestFile, { noremap = true, silent = true })
vim.keymap.set("n", "t<C-f>", vim.cmd.TestSuite, { noremap = true, silent = true })
vim.keymap.set("n", "t<C-s>", vim.cmd.Testlast, { noremap = true, silent = true })
vim.keymap.set("n", "t<C-g>", vim.cmd.TestVisit, { noremap = true, silent = true })

-- Switch panes sides
vim.keymap.set("n", "<leader>j", "<C-w>R")
vim.keymap.set("n", "<leader>k", "<C-w>L")

vim.keymap.set("n", "<leader>mdp", vim.cmd.MarkdownPreview, { noremap = true, silent = true })
