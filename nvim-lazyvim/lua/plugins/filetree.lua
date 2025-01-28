vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      window = {
        position = "left",
        auto_close = true,
      },
    })
    vim.keymap.set("n", "<leader>]", ":Neotree toggle<CR>", {})
    -- vim.keymap.set("n", "<leader>[", ":Neotree reveal float<CR>", {})
    vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>", {})
    vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
  end,
}
