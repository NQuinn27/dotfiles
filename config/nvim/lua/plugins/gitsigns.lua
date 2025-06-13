return {
	"lewis6991/gitsigns.nvim",
	opts = {
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
			end

			map("n", "<leader>gs", gs.stage_hunk, "Git Stage Hunk")
			map("v", "<leader>gs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git Stage Hunk (Visual)")
			map("n", "<leader>gr", gs.reset_hunk, "Git Reset Hunk")
			map("v", "<leader>gr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git Reset Hunk (Visual)")
			map("n", "<leader>gS", gs.stage_buffer, "Git Stage Buffer")
			map("n", "<leader>gR", gs.reset_buffer, "Git Reset Buffer")

			map("n", "<leader>gu", gs.undo_stage_hunk, "Git Undo Stage Hunk")
			map("n", "<leader>gp", gs.preview_hunk, "Git Preview Hunk")

			map("n", "<leader>gbl", function()
				gs.blame_line({ full = true })
			end, "Blame Line")
			map("n", "<leader>gb", gs.toggle_current_line_blame, "Git Toggle Blame")

			map("n", "<leader>gd", gs.diffthis, "Git Diff This")
			map("n", "<leader>gD", function()
				gs.diffthis("~")
			end, "Diff this ~")

			-- Navigation
			map("n", "]h", gs.next_hunk, "Next Git Hunk")
			map("n", "[h", gs.prev_hunk, "Previous Git Hunk")

			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git Select Hunk")
		end,
	},
}
