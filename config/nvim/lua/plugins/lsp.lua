return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig",
		"saghen/blink.cmp",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local util = require("lspconfig.util")
		lspconfig.lua_ls.setup({})
		-- Global mappings.
		-- See `:help vim.diagnostic.*` for documentation on any of the below functions
		vim.keymap.set("n", "<leader>D", vim.diagnostic.open_float)
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
				-- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
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
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local default_setup = function(server)
			require("lspconfig")[server].setup({
				capabilities = capabilities,
			})
		end

		-- Auto setup for servers
		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = { "ts_ls", "lua_ls", "pyright", "yamlls", "gopls", "cucumber_language_server" },
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
				},
			},
		})

		-- lspconfig.rust_analyzer.setup({
		-- 	-- Server-specific settings. See `:help lspconfig-setup`
		-- 	settings = {
		-- 		["rust-analyzer"] = {
		-- 			cargo = {
		-- 				allFeatures = true,
		-- 			},
		-- 			imports = {
		-- 				group = {
		-- 					enable = false,
		-- 				},
		-- 			},
		-- 			completion = {
		-- 				postfix = {
		-- 					enable = false,
		-- 				},
		-- 			},
		-- 		},
		-- 	},
		-- })

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

		lspconfig.cucumber_language_server.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			cmd = { "cucumber-language-server", "--stdio" },
			runtime = {
				version = "0.0.1",
				path = "cucumber-language-server",
			},
		})

		lspconfig.gopls.setup({
			diagnostics = {
				virtual_text = false, -- don't use neovim's default virtual_text now we're using "rachartier/tiny-inline-diagnostic.nvim"
			},
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_dir = util.root_pattern("go.work", "go.mod", ".git"),
			-- DISABLED: FixGoImports
			--
			-- Instead I use https://github.com/incu6us/goimports-reviser
			-- Via https://github.com/stevearc/conform.nvim
			--
			-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			--   group = vim.api.nvim_create_augroup("FixGoImports",
			--     { clear = true }),
			--   pattern = "*.go",
			--   callback = function()
			--     -- ensure imports are sorted and grouped correctly
			--     local params = vim.lsp.util.make_range_params()
			--     params.context = { only = { "source.organizeImports" } }
			--     local result =
			--         vim.lsp.buf_request_sync(0,
			--           "textDocument/codeAction",
			--           params)
			--     for _, res in pairs(result or {}) do
			--       for _, r in pairs(res.result or {}) do
			--         if r.edit then
			--           vim.lsp.util.apply_workspace_edit(
			--             r.edit, "UTF-8")
			--         else
			--           vim.lsp.buf.execute_command(r.command)
			--         end
			--       end
			--     end
			--   end
			-- })

			-- DISABLED:
			-- I don't use revive separately anymore. It's only used via golangci-lint.
			--
			-- vim.keymap.set("n", "<leader><leader>lv",
			--                "<Cmd>cex system('revive -exclude vendor/... ./...') | cwindow<CR>",
			--                {
			--     noremap = true,
			--     silent = true,
			--     buffer = bufnr,
			--     desc = "lint project code (revive)"
			-- })
			settings = {
				-- https://go.googlesource.com/vscode-go/+/HEAD/docs/settings.md#settings-for
				-- https://www.lazyvim.org/extras/lang/go (borrowed some ideas from here)
				gopls = {
					complete_unimported = true,
					usePlaceholders = true,
					analyses = {
						fieldalignment = false, -- find structs that would use less memory if their fields were sorted
						nilness = true,
						unusedparams = true,
						unusedwrite = true,
						useany = true,
					},
					-- codelenses = {
					--     gc_details = false,
					--     generate = true,
					--     regenerate_cgo = true,
					--     run_govulncheck = true,
					--     test = true,
					--     tidy = true,
					--     upgrade_dependency = true,
					--     vendor = true,
					-- },
					-- experimentalPostfixCompletions = true,
					-- hints = {
					--     assignVariableTypes = true,
					--     compositeLiteralFields = true,
					--     compositeLiteralTypes = true,
					--     constantValues = true,
					--     functionTypeParameters = true,
					--     parameterNames = true,
					--     rangeVariableTypes = true
					-- },
					gofumpt = true,
					-- semanticTokens = true,
					-- DISABLED: staticcheck
					--
					-- gopls doesn't invoke the staticcheck binary.
					-- Instead it imports the analyzers directly.
					-- This means it can report on issues the binary can't.
					-- But it's not a good thing (like it initially sounds).
					-- You can't then use line directives to ignore issues.
					--
					-- Instead of using staticcheck via gopls.
					-- We have golangci-lint execute it instead.
					--
					-- For more details:
					-- https://github.com/golang/go/issues/36373#issuecomment-570643870
					-- https://github.com/golangci/golangci-lint/issues/741#issuecomment-1488116634
					--
					-- staticcheck = true,
				},
			},
			-- DISABLED: as it overlaps with `lvimuser/lsp-inlayhints.nvim`
			-- init_options = {
			--   usePlaceholders = true,
			-- }
		})
	end,
}
