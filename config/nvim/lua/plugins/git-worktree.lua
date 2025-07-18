return {
	"ThePrimeagen/git-worktree.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local gitworktree = require("git-worktree")

		gitworktree.setup()

		require("telescope").load_extension("git_worktree")

		-- HACK by default
		-- <Enter> switched to that worktree
		-- <c-d> deletes that worktree
		-- <c-f> toggles forcing of the next deletion

		vim.keymap.set("n", "<leader>wl", function()
			require("telescope").extensions.git_worktree.git_worktrees()
		end, { desc = "List Git Worktrees" })

		vim.keymap.set("n", "<leader>wc", function()
			require("telescope").extensions.git_worktree.create_git_worktree()
		end, { desc = "Create Git Worktree" })
	end,
}
