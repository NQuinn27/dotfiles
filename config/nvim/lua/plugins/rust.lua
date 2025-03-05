return {
	{
		"rust-lang/rust.vim",
		ft = { "rust" },
		config = function()
			vim.g.rustfmt_autosave = 1
			vim.g.rustfmt_emit_files = 1
			vim.g.rustfmt_fail_silently = 0
			vim.g.rust_clip_command = "wl-copy"
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		version = vim.fn.has("nvim-0.10.0") == 0 and "^4" or false,
		ft = { "rust" },
	},
}
