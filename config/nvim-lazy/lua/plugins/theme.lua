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
    },
  },
  {
    "sainnhe/gruvbox-material",
    name = "gruvbox-material",
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "original"
    end,
  },
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
  {
    lazy = false,
    priority = 1000,
    -- dir = "~/plugins/colorbuddy.nvim",
    "tjdevries/colorbuddy.nvim",
    config = function()
      -- vim.cmd.colorscheme("gruvbuddy")
    end,
  },
  {
    "vague-theme/vague.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
      -- NOTE: you do not need to call setup if you don't want to.
      require("vague").setup({
        -- optional configuration here
      })
      vim.cmd("colorscheme vague")
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = true,
    opts = {
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      inverse = true, -- invert background for search, diffs, statuslines and errors
      contrast = "hard", -- can be "hard", "soft" or empty string
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
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
        -- vim.cmd("colorscheme catppuccin-frappe")
        -- vim.cmd("colorscheme gruvbox-material")
        -- require("vscode").load("dark")
        -- vim.api.nvim_set_hl(0, "Normal", { bg = "#1E2021" })
        -- vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "#181818" })
        -- vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#FBBC2E", bg = "none", nocombine = true })
        -- vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = "#181818" })
        -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#181818" })
        -- vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "#181818" })
        -- vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#181818" })
      end,
      set_light_mode = function()
        vim.o.background = "light"
        -- vim.cmd("colorscheme gruvbox-material")
        require("vscode").load("light")
        vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "#F8F8F8" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#90D5FF", bg = "#F8F8F8", nocombine = true })
        vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = "#F8F8F8" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#F8F8F8" })
        vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "#F8F8F8" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#F8F8F8" })
      end,
    },
  },
}
