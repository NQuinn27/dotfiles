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
                if vim.bo[bufnr].filetype == "yaml" then
                    return
                end

                -- These options will be passed to conform.format()
                return {
                    timeout_ms = 500,
                    lsp_fallback = true,
                }
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
}
