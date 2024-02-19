return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- optional
    'MunifTanjim/nui.nvim'
  },
  config = function() 
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>]", vim.cmd.NvimTreeToggle, { noremap = true, silent = true })
  end
}
