return {
	"williamboman/mason.nvim",
	dependencies = {
		"saghen/blink.cmp",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Setup Mason for installing language servers
		require("mason").setup({
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		})

		-- Setup mason-lspconfig to automatically install LSP servers
		require("mason-lspconfig").setup({
			ensure_installed = {
				"ts_ls",
				"pyright",
				"lua_ls",
				"yamlls",
				"cucumber_language_server",
				"gopls",
				"bashls",
			},
			automatic_installation = true,
		})

		-- Global mappings.
		-- See `:help vim.diagnostic.*` for documentation on any of the below functions
		vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Open diagnostic float" })
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

		-- Keymap for normal mode, enter opens float
		-- after the language server attaches to the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			callback = function(event)
				local opts = { buffer = event.buf }

				-- these will be buffer-local keybindings
				-- because they only work if you have an active language server

				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
				-- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
				vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
				vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
				vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
				vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
				vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
				vim.keymap.set(
					"n",
					"<leader>rn",
					"<cmd>lua vim.lsp.buf.rename()<cr>",
					vim.tbl_extend("force", opts, { desc = "Rename symbol" })
				)
				vim.keymap.set(
					"n",
					"<leader>ca",
					"<cmd>lua vim.lsp.buf.code_action()<cr>",
					vim.tbl_extend("force", opts, { desc = "Code action" })
				)
				vim.keymap.set(
					{ "n", "x" },
					"<leader>cf",
					"<cmd>lua vim.lsp.buf.format({async = true})<cr>",
					vim.tbl_extend("force", opts, { desc = "Format buffer" })
				)
			end,
		})

		vim.diagnostic.config({
			virtual_text = true,
		})

		-- Create a custom LspInfo command
		vim.api.nvim_create_user_command("LspInfoLocal", function()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				print("No LSP clients attached to current buffer")
				return
			end

			for _, client in ipairs(clients) do
				print(string.format("Client: %s (id: %d)", client.name, client.id))
				print(string.format("  Root dir: %s", client.root_dir or "N/A"))
				print(string.format("  Filetypes: %s", table.concat(client.config.filetypes or {}, ", ")))
			end
		end, { desc = "Show LSP client info for current buffer" })

		-- Get capabilities from blink.cmp
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		-- Global LSP configuration (applies to all servers)
		vim.lsp.config("*", {
			capabilities = capabilities,
			root_markers = { ".git" },
		})
		-- TypeScript/JavaScript
		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
			root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
		})

		-- Python
		vim.lsp.config("pyright", {
			cmd = { "pyright-langserver", "--stdio" },
			filetypes = { "python" },
			root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
		})

		-- Lua
		vim.lsp.config("lua_ls", {
			cmd = { "lua-language-server" },
			filetypes = { "lua" },
			root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		-- YAML
		vim.lsp.config("yamlls", {
			cmd = { "yaml-language-server", "--stdio" },
			filetypes = { "yaml", "yaml.docker-compose" },
			root_markers = { ".git" },
			settings = {
				redhat = {
					telemetry = {
						enabled = false,
					},
				},
				yaml = {
					keyOrdering = false,
					format = {
						enable = true,
						proseWrap = "preserve",
						retainLineBreaks = true,
					},
				},
			},
		})

		-- Cucumber
		vim.lsp.config("cucumber_language_server", {
			cmd = { "cucumber-language-server", "--stdio" },
			filetypes = { "cucumber", "feature" },
			root_markers = { "features", ".git" },
			settings = {
				cucumber = {
					features = { "features/**/*.feature" },
					glue = { "src/**/*.ts" },
				},
			},
		})

		-- Swift (SourceKit-LSP)
		vim.lsp.config("sourcekit", {
			cmd = { "sourcekit-lsp" },
			filetypes = { "swift", "objective-c", "objective-cpp" },
			root_markers = { "Package.swift", ".git" },
			capabilities = vim.tbl_deep_extend("force", capabilities, {
				workspace = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
					},
				},
			}),
		})

		-- Go
		vim.lsp.config("gopls", {
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_markers = { "go.work", "go.mod", ".git" },
			settings = {
				gopls = {
					completeUnimported = true,
					usePlaceholders = true,
					analyses = {
						unusedparams = true,
					},
					gofumpt = true,
				},
			},
		})

		vim.lsp.config.bashls = {
			cmd = { "bash-language-server", "start" },
			filetypes = { "bash", "sh" },
		}

		-- Enable all configured servers
		vim.lsp.enable({
			"ts_ls",
			"pyright",
			"lua_ls",
			"yamlls",
			"cucumber_language_server",
			"sourcekit",
			"gopls",
			"bashls",
		})
	end,
}
