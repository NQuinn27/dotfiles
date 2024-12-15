return {
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   priority = 1000,
  --   config = function()
  --     require("catppuccin").setup({
  --       flavour = "macchiato",
  --       -- transparent_background = true,
  --       background = {
  --         dark = "mocha",
  --         light = "latte",
  --       },
  --     })
  --     vim.cmd.colorscheme("catppuccin")
  --   end,
  -- }
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.tokyonight_style = "night"
      vim.g.tokyonight_italic_functions = true
      vim.g.tokyonight_italic_variables = true
      vim.g.tokyonight_sidebars = { "qf", "vista_kind", "terminal", "packer" }
      vim.g.tokyonight_colors = { hint = "orange", error = "#ff0000" }
      vim.cmd("colorscheme tokyonight-day")
    end,
  }
}
