require("bufferline").setup{
  options = {
    mode = "buffers",
    separator_style = "slope",
    offsets = {
        {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true -- use a "true" to enable the default, or set your own character
        }
    }
  }
}
-- Closing Buffers
vim.keymap.set("n", "<leader>bcr", vim.cmd.BufferLineCloseRight, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bcl", vim.cmd.BufferLineCloseLeft, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bco", vim.cmd.BufferLineCloseOthers, { noremap = true, silent = true })

-- Cycling the Buffers
vim.keymap.set("n", "<leader>bn", vim.cmd.BufferLineCycleNext, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bp", vim.cmd.BufferLineCyclePrev, { noremap = true, silent = true })

-- Moving the Buffers
vim.keymap.set("n", "<leader>bm", vim.cmd.BufferLineMoveNext, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bM", vim.cmd.BufferLineMovePrev, { noremap = true, silent = true })
