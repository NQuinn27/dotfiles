return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre ~/vaults/notes/*.md",
  --   "BufNewFile ~/vaults/notes/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "notes",
        path = "~/vaults/notes",
      },
    },
    -- {
    --   name = "work",
    --   path = "~/vaults/work",
    -- },
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
  },
}
