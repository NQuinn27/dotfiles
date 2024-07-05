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
}
