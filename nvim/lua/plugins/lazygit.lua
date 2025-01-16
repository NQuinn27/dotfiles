return {
    "kdheepak/lazygit.nvim",
    -- optional for floating window border decoration
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gg", vim.cmd.LazyGit, desc = "LazyGit" },
    }
}
