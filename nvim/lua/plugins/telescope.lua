return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-telescope/telescope-file-browser.nvim",
	},
	config = function()
		require("telescope").setup({
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"-u",
				},
				file_ignore_patterns = { ".git/", "node_modules/" },
				mappings = {
					i = {
						["<C-u>"] = false,
						["<C-d>"] = false,
					},
				},
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
				file_browser = {
					theme = "ivy",
					-- disables netrw and use telescope-file-browser in its place
					hijack_netrw = true,
					mappings = {
						["i"] = {
							-- your custom insert mode mappings
						},
						["n"] = {
							-- your custom normal mode mappings
						},
					},
				},
			},
		})

		-- Enable telescope fzf native, if installed
		pcall(require("telescope").load_extension, "fzf")

		-- See `:help telescope.builtin`
		vim.keymap.set("n", "<leader>eb", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
		vim.keymap.set("n", "<leader>/", function()
			-- You can pass additional configuration to telescope to change theme, layout, etc.
			require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 10,
				previewer = false,
			}))
		end, { desc = "[/] Fuzzily search in current buffer]" })

		vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
		vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
		vim.keymap.set(
			"n",
			"<leader>sw",
			require("telescope.builtin").grep_string,
			{ desc = "[S]earch current [W]ord" }
		)
		vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
		vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
		vim.keymap.set("n", "<C-p>", require("telescope.builtin").git_files, { desc = "[C-p] Find git files" })

		--[[ 	 ]] -- Git related searches
		vim.keymap.set("n", "<leader>gc", require("telescope.builtin").git_commits, { desc = "[G]it [C]ommits" })
		vim.keymap.set("n", "<leader>gb", require("telescope.builtin").git_branches, { desc = "[G]it [B]ranches" })
		vim.keymap.set("n", "<leader>gs", require("telescope.builtin").git_status, { desc = "[G]it [S]tatus" })

		-- Marks and Registers
		vim.keymap.set("n", "<leader>sm", require("telescope.builtin").marks, { desc = "[S]earch [M]arks" })
		vim.keymap.set("n", "<leader>sr", require("telescope.builtin").registers, { desc = "[S]earch [R]egisters" })

		-- Treesitter
		vim.keymap.set("n", "<leader>st", require("telescope.builtin").treesitter, { desc = "[S]earch [T]reesitter" })

		-- Resume last search
		vim.keymap.set("n", "<leader>sl", require("telescope.builtin").resume, { desc = "[S]earch [L]ast" })

		-- File browser
		vim.keymap.set("n", "<leader>fb", function()
			require("telescope").extensions.file_browser.file_browser()
		end, { desc = "[F]ile [B]rowser" })

		-- Find all files (including hidden ones, but excluding .git)
		vim.keymap.set("n", "<leader>sa", function()
			require("telescope.builtin").find_files({
				hidden = true,
				no_ignore = true,
				file_ignore_patterns = { ".git/" },
			})
		end, { desc = "[S]earch [A]ll files" })

		require("telescope").load_extension("ui-select")
	end,
}
