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
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      dim_inactive = {
        enabled = true,
        shade = "dark",
        percentage = 0.15,
      },
      styles = {
        keywords = { "italic" },
      },
      lsp_styles = {
        inlay_hints = {
          background = false,
        },
      },
    },
  },
  { "sainnhe/gruvbox-material", name = "gruvbox-material" },
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    ---@type solarized.config
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      vim.o.background = "light"
      require("solarized").setup(opts)
      vim.cmd.colorscheme("solarized")
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.o.background = "dark"
        -- vim.cmd("colorscheme catppuccin")
        -- vim.cmd("colorscheme gruvbox-material")
        require("vscode").load("dark")
        vim.api.nvim_set_hl(0, "Normal", { bg = "#1D1D1D" })
        vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "#181818" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#D7BA7D", bg = "none", nocombine = true })
        vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = "#181818" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#181818" })
        vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "#181818" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#181818" })
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
