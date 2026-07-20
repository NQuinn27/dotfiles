return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				-- Formatters
				"stylua",
				"rubocop",
				"prettier",
				"ruff",
				"gofumpt",
				"goimports",
				"jq",
				"swiftformat",
				-- Linters
				"swiftlint",
				"luacheck",
				"eslint_d",
				"golangci-lint",
				"jsonlint",
			},
			auto_update = false,
			run_on_start = true,
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				ruby = { "rubocop" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				swift = { "swiftformat" },
				rust = { "rustfmt" },
				python = { "ruff_format" },
				go = { "gofumpt", "goimports" },
				json = { "jq" },
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
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				swift = { "swiftlint" },
				rust = { "clippy" },
				python = { "ruff" },
				go = { "golangcilint" },
				json = { "jsonlint" },
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
