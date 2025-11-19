return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = false,
      italic_comments = true,
      underline_links = true,
      disable_nvimtree_bg = false,
      group_overrides = {
        -- Snacks Explorer sidebar backgrounds
        SnacksNormal = { bg = "#181818" },
        SnacksNormalNC = { bg = "#181818" },
        -- Float backgrounds
        NormalFloat = { bg = "#181818" },
        FloatBorder = { bg = "#181818" },
      },
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
        vim.o.background = "dark"
        require("vscode").load("dark")
      end,
      set_light_mode = function()
        vim.o.background = "light"
        require("vscode").load("light")
      end,
    },
  },
}
