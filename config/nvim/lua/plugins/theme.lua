return {
  {
    "maxmx03/solarized.nvim",
    lazy = true,
    priority = 1000,
    opts = {},
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    priority = 1000,
    opts = {
      flavour = "macchiato",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- Colorscheme will be set by auto-dark-mode
      end,
    },
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.cmd("colorscheme catppuccin")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd("colorscheme solarized")
      end,
    },
  },
}
