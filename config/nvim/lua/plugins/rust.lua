return {
	{
		"rust-lang/rust.vim",
		ft = { "rust" },
		config = function()
			local platform = require("platform")

			vim.g.rustfmt_autosave = 1
			vim.g.rustfmt_emit_files = 1
			vim.g.rustfmt_fail_silently = 0

			if platform.is_macos() and platform.executable("pbcopy") then
				vim.g.rust_clip_command = "pbcopy"
			elseif vim.env.WAYLAND_DISPLAY and platform.executable("wl-copy") then
				vim.g.rust_clip_command = "wl-copy"
			elseif platform.executable("xclip") then
				vim.g.rust_clip_command = "xclip -selection clipboard"
			elseif platform.executable("xsel") then
				vim.g.rust_clip_command = "xsel --clipboard --input"
			end
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		opts = {
			server = {
				on_attach = function(_, bufnr)
					vim.keymap.set("n", "<leader>cR", function()
						vim.cmd.RustLsp("codeAction")
					end, { desc = "Code Action", buffer = bufnr })
				end,
				default_settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
							loadOutDirsFromCheck = true,
							buildScripts = {
								enable = true,
							},
						},
						check = {
							command = "clippy",
						},
						procMacro = {
							enable = true,
						},
						files = {
							exclude = {
								".direnv",
								".git",
								".jj",
								".github",
								".gitlab",
								"bin",
								"node_modules",
								"target",
								"venv",
								".venv",
							},
							-- Avoid Roots Scanned hanging in very large repos.
							watcher = "client",
						},
					},
				},
			},
		},
		config = function(_, opts)
			local platform = require("platform")
			local codelldb = platform.codelldb_paths()

			if platform.readable(codelldb.adapter) and platform.readable(codelldb.liblldb) then
				opts.dap = {
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb.adapter, codelldb.liblldb),
				}
			end

			vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
		end,
	},
	{
		"Saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			completion = {
				crates = {
					enabled = true,
				},
			},
			lsp = {
				enabled = true,
				actions = true,
				completion = true,
				hover = true,
			},
		},
	},
}
