return {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    -- event = {
    --   "BufReadPre Users/niall/Documents/Notes/**/**.md",
    --   "BufNewFile Users/niall/Documents/Notes/**/**.md",
    -- },
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
    },
    config = function()
        vim.opt.conceallevel = 2
        require("obsidian").setup({
            workspaces = {
                {
                    name = "notes",
                    path = "~/vaults/notes"
                }
            },
            daily_notes = {
                folder = "daily",
                date_format = "%Y/%m-%b/%Y-%m-%d",
                template = "T_Daily.md"
            },
            templates = {
                folder = "Z_Templates",
            },
            attachments = {
                img_folder = "Z_Assets"
            }
        })
    end
}
