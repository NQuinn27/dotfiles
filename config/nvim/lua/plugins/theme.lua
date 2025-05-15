return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "macchiato",
        background = {
          dark = "frappe",
          light = "macchiato",
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

-- {
-- "folke/tokyonight.nvim",
-- lazy = false,
-- priority = 1000,
-- config = function()
--     require("tokyonight").setup({
--         light_style = "day",
--     })
--     vim.cmd.colorscheme("tokyonight")
-- end,
