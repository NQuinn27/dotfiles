return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  -- event = {
  --   "BufReadPre Users/niall/Documents/Notes/**/**.md",
  --   "BufNewFile Users/niall/Documents/Notes/**/**.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- Set markdown-specific settings
    vim.opt.conceallevel = 2
    require("obsidian").setup({
      workspaces = {
        {
          name = "notes",
          path = "~/vaults/notes",
        },
      },
      daily_notes = {
        folder = "daily",
        date_format = "%Y/%m-%b/%Y-%m-%d",
        template = "T_Daily.md",
      },
      templates = {
        folder = "Z_Templates",
      },
      attachments = {
        img_folder = "Z_Assets",
      },
      follow_url_func = function(url)
        -- Open the URL in the default web browser.
        vim.fn.jobstart({ "open", url }) -- Mac OS
        -- vim.fn.jobstart({"xdg-open", url})  -- linux
        -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
        -- vim.ui.open(url) -- need Neovim 0.10.0+
      end,
    })
  end,
}
