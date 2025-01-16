return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig",
        "saghen/blink.cmp",
	},
	config = function()
		local lspconfig = require("lspconfig")
		lspconfig.lua_ls.setup({})
		-- Global mappings.
		-- See `:help vim.diagnostic.*` for documentation on any of the below functions
		vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)
		-- Keymap for normal mode, enter opens float
		-- after the language server attaches to the current buffer
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			callback = function(event)
				local opts = { buffer = event.buf }

				-- these will be buffer-local keybindings
				-- because they only work if you have an active language server

				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
				vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
				vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
				vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
				vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
				vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
				vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
				vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
				vim.keymap.set({ "n", "x" }, "<leader>ff", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
				vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
			end,
		})

		vim.diagnostic.config({
			virtual_text = true,
		})
		-- Set up lspconfig.
        local capabilities = require('blink.cmp').get_lsp_capabilities()

		local default_setup = function(server)
			require("lspconfig")[server].setup({
				capabilities = capabilities,
			})
		end

		-- Auto setup for servers
		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = { "ts_ls", "lua_ls", "pyright", "yamlls" },
			handlers = {
				default_setup,
				yamlls = function()
					lspconfig.yamlls.setup({
						settings = {
							yaml = {
								keyOrdering = false,
							},
						},
					})
				end,
			},
		})

		lspconfig.lua_ls.setup({
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				}
			}
		})

		lspconfig.sourcekit.setup({
			cmd = {
				"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
			},
			settings = {
				sourcekit = {
					toolchain = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain",
					buildFlags = {
						"-sdk",
						"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk",
					},
				},
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})
	end,
}
