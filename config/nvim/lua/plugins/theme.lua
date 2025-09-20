return {
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        snacks = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
          end
        end,
      },
    },
  },
  -- {
  --   "navarasu/onedark.nvim",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require("onedark").setup({
  --       style = "darker",
  --     })
  --     -- Enable theme
  --     require("onedark").load()
  --   end,
  -- },
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     colorscheme = "catppuccin-frappe",
  --   },
  -- },

  { "f-person/auto-dark-mode.nvim" },
  opts = {
    update_interval = 1000, -- Check every 1 second
    set_dark_mode = function()
      vim.cmd([[colorscheme catppuccin-frappe]]) -- Replace with your dark theme
    end,
    set_light_mode = function()
      vim.cmd([[colorscheme catppuccin-latte]]) -- Replace with your light theme
    end,
  },
}
