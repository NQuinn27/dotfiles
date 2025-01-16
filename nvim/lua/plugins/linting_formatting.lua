return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				ruby = { "rubocop" },
				-- javascript = { "prettier" },
				-- typescript = { "prettier" },
				swift = { "swiftformat" },
				rust = { "astgrep" },
				python = { "black" },
				go = { "gofmt" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_fallback = true,
			},
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
				python = { "flake8" },
                go = { "golangci_lint" },
			}
		end,
	},
}
