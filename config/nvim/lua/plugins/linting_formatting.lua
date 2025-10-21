return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                ruby = { "rubocop" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                swift = { "swiftformat" },
                rust = { "astgrep" },
                python = { "ruff" },
                go = { "gofumpt", "goimports", "goimports-reviser" },
                json = { "jq" },
                gherkin = { "gherkin-lint" },
            },
            format_on_save = function(bufnr)
                if vim.g.autoformat then
                    local disable_filetypes = {}
                    local lsp_format_opt
                    if disable_filetypes[vim.bo[bufnr].filetype] then
                        lsp_format_opt = "never"
                    else
                        lsp_format_opt = "fallback"
                    end
                    return {
                        timeout_ms = 500,
                        lsp_format = lsp_format_opt,
                    }
                else
                    return
                end
            end,
        },
    },
    {
        "mfussenegger/nvim-lint",
        config = function()
            require("lint").linters_by_ft = {
                lua = { "luacheck" },
                ruby = { "rubocop" },
                javascript = { "eslint" },
                typescript = { "eslint" },
                swift = { "swiftlint" },
                rust = { "cargo" },
                python = { "ruff" },
                go = { "codespell", "golangcilint" },
                json = { "jsonlint" },
                gherkin = { "gherkin-lint" },
            }
        end,
    },
    { -- Assuming you init/setup snacks.nvim in a different file
        "folke/snacks.nvim",
        opts = function()
            vim.g.autoformat = true -- Sets up the default value to be true

            require("snacks").toggle
                .new({
                    id = "Format on Save",
                    name = "Format on Save",
                    get = function()
                        return vim.g.autoformat
                    end,
                    set = function(_)
                        vim.g.autoformat = not vim.g.autoformat
                    end,
                })
                :map("<leader>uf")
        end,
    },
}
