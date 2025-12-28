return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSUpdate", "TSInstall" },
		config = function()
			-- Install parsers
			require("nvim-treesitter").install({
				"c",
				"cpp",
				"go",
				"lua",
				"python",
				"rust",
				"ron",
				"typescript",
				"vim",
				"ruby",
				"markdown",
				"markdown_inline",
				"javascript",
				"yaml",
			})

			-- Enable highlighting
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})

			-- Register markdown for mdx/md
			vim.treesitter.language.register("markdown", "mdx")
			vim.treesitter.language.register("markdown", "md")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			-- Textobjects select
			local select_maps = {
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			}
			for keymap, query in pairs(select_maps) do
				vim.keymap.set({ "x", "o" }, keymap, function()
					require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
				end)
			end

			-- Textobjects move
			local ts_move = require("nvim-treesitter-textobjects.move")
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				ts_move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				ts_move.goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				ts_move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				ts_move.goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				ts_move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				ts_move.goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				ts_move.goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				ts_move.goto_previous_end("@class.outer", "textobjects")
			end)

			-- Textobjects swap
			local ts_swap = require("nvim-treesitter-textobjects.swap")
			vim.keymap.set("n", "<leader>a", function()
				ts_swap.swap_next("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>A", function()
				ts_swap.swap_previous("@parameter.inner")
			end)
		end,
	},
	{
		"RRethy/nvim-treesitter-endwise",
		event = "InsertEnter",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},
}
