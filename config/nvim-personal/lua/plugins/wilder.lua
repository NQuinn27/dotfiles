return {
	"gelguy/wilder.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"romgrk/fzy-lua-native",
	},
	config = function()
		local wilder = require("wilder")
		wilder.setup({ modes = { ":", "/", "?" } })
		wilder.set_option(
			"renderer",
			wilder.popupmenu_renderer({
				highlighter = wilder.highlighter_with_gradient({
					wilder.basic_highlighter(),
					wilder.lua_fzy_highlighter(),
				}),
				highlights = {
					accent = "WildMenu",
					default = "NormalFloat",
					border = "FloatBorder",
				},
				left = { " ", wilder.popupmenu_devicons() },
				right = { " ", wilder.popupmenu_scrollbar() },
				min_width = "50%",
				max_height = 20,
			})
		)
	end,
}
