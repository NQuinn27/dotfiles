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
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.o.background = "dark"
        require("vscode").load("dark")
        vim.api_nvim_set_hl(0, "SnacksNormal", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "SnacksPicker", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "SnacksPickerBorder", { fg = "#D7BA7D", bg = "none", nocombine = "true"})
        vim.api_nvim_set_hl(0, "SnacksNormalNC", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "NormalFloat", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "FloatBorder", { bg = "#181818"})
      end,
      set_light_mode = function()
        vim.o.background = "light"
        require("vscode").load("light")
        vim.api_nvim_set_hl(0, "SnacksNormal", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "SnacksPicker", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "SnacksPickerBorder", { fg = "#90D5FF", bg = "none", nocombine = "true"})
        vim.api_nvim_set_hl(0, "SnacksNormalNC", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "NormalFloat", { bg = "#181818"})
        vim.api_nvim_set_hl(0, "FloatBorder", { bg = "#181818"})
      end,
    },
  },
}
