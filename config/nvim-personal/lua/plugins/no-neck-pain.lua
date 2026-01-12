return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	keys = {
		{
			"<leader>;",
			":NoNeckPain<CR>",
			desc = "Toggle No Neck Pain",
		},
	},
	opts = {
		width = 140,
		buffers = {
			scratchPad = {
				-- set to `false` to
				-- disable auto-saving
				enabled = true,
				-- set to `nil` to default
				-- to current working directory
				location = "~/Documents/",
			},
			bo = {
				filetype = "md",
			},
			wo = {
				fillchars = "eob: ",
			},
		},
	},
}
