return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      strategies = {
        chat = {
          adapter = "anthropic",
        },
        inline = {
          adapter = "copilot",
        },
      },
      display = {
        chat = {
          window = {
            position = "right",
          },
        },
      },
    })
    -- Add a keymap to show Code Companion Help
    vim.api.nvim_set_keymap(
      "n",
      "<C-a>",
      "<cmd>CodeCompanionActions<cr>",
      { noremap = true, silent = true, desc = "Code Companion Actions" }
    )
    vim.api.nvim_set_keymap(
      "v",
      "<C-a>",
      "<cmd>CodeCompanionActions<cr>",
      { noremap = true, silent = true, desc = "Code Companion Actions" }
    )
    vim.api.nvim_set_keymap(
      "n",
      "<leader>aa",
      "<cmd>CodeCompanionChat Toggle<cr>",
      { noremap = true, silent = true, desc = "Code Companion Chat" }
    )
    vim.api.nvim_set_keymap(
      "v",
      "<leader>aa",
      "<cmd>CodeCompanionChat Toggle<cr>",
      { noremap = true, silent = true, desc = "Code Companion Chat" }
    )
    vim.api.nvim_set_keymap(
      "v",
      "ga",
      "<cmd>CodeCompanionChat Add<cr>",
      { noremap = true, silent = true, desc = "Code Companion Chat Add" }
    )
  end,
}
