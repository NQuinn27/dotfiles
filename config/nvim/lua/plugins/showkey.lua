return {
	{
		"nvzone/showkeys",
		cmd = "ShowkeysToggle",
		keys = {
			{ "<leader>uk", ":ShowkeysToggle<CR>", desc = "Toggle ShowKeys" },
		},
		opts = {
			maxkeys = 3,
			show_count = true,
			winopts = {
				focusable = false,
				relative = "editor",
				style = "minimal",
				border = "single",
				height = 1,
				row = 1,
				col = 0,
			},
		},
	},
}
