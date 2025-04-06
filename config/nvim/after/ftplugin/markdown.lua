vim.opt.conceallevel = 2
vim.opt.textwidth = 120 -- Set text width to 80 characters
vim.opt_local.wrap = true -- Enable line wrapping
vim.opt_local.linebreak = true -- Wrap at word boundaries
vim.opt_local.formatoptions = vim.opt_local.formatoptions + "ta" -- Auto-wrap text using textwidth
