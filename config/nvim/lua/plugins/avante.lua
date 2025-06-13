return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	version = false, -- Never set this value to "*"! Never!
	opts = {
		-- add any opts here
		system_prompt = function()
			local hub = require("mcphub").get_hub_instance()
			return hub and hub:get_active_servers_prompt() or ""
		end,
		-- The custom_tools type supports both a list and a function that returns a list. Using a function here prevents requiring mcphub before it's loaded
		custom_tools = function()
			return {
				require("mcphub.extensions.avante").mcp_tool(),
			}
		end,
		providers = {
			claude = {
				model = "claude-sonnet-4-20250514",
				api_key = os.getenv("ANTHROPIC_API_KEY"),
				extra_request_body = {
					max_tokens = 8192, -- Set this to the max tokens you want to use
				},
			},
		},
		selector = {
			provider = "snacks",
		},
		-- for example
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
