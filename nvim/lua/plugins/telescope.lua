return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<C-u>"] = false,
            ["<C-d>"] = false,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
      },
    })

    -- Enable telescope fzf native, if installed
    pcall(require("telescope").load_extension, "fzf")

    -- See `:help telescope.builtin`
    vim.keymap.set(
      "n",
      "<leader>?",
      require("telescope.builtin").oldfiles,
      { desc = "[?] Find recently opened files" }
    )
    vim.keymap.set(
      "n",
      "<leader>eb",
      require("telescope.builtin").buffers,
      { desc = "[ ] Find existing buffers" }
    )
    vim.keymap.set("n", "<leader>/", function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
      }))
    end, { desc = "[/] Fuzzily search in current buffer]" })

    vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set(
      "n",
      "<leader>sw",
      require("telescope.builtin").grep_string,
      { desc = "[S]earch current [W]ord" }
    )
    vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
    vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<C-p>", require("telescope.builtin").git_files, { desc = "[C-p] Find git files" })

    require("telescope").load_extension("ui-select")
  end,
}
