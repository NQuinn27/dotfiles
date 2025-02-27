return {
	"wojciech-kulik/xcodebuild.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-tree.lua", -- (optional) to manage project files
		"nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
	},
	keys = {
		{ "<leader>X", "<cmd>XcodebuildPicker<cr>", desc = "Show Xcodebuild Actions" },
		{ "<leader>xf", "<cmd>XcodebuildProjectManager<cr>", desc = "Show Project Manager Actions" },

		{ "<leader>xb", "<cmd>XcodebuildBuild<cr>", desc = "Build Project" },
		{ "<leader>xB", "<cmd>XcodebuildBuildForTesting<cr>", desc = "Build For Testing" },
		{ "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", desc = "Build & Run Project" },

		{ "<leader>xt", "<cmd>XcodebuildTest<cr>", desc = "Run Tests" },
		{ "<leader>xt", mode = "v", "<cmd>XcodebuildTestSelected<cr>", desc = "Run Selected Tests" },
		{ "<leader>xT", "<cmd>XcodebuildTestClass<cr>", desc = "Run Current Test Class" },
		{ "<leader>x.", "<cmd>XcodebuildTestRepeat<cr>", desc = "Repeat Last Test Run" },

		{ "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", desc = "Toggle Xcodebuild Logs" },
		{ "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", desc = "Toggle Code Coverage" },
		{ "<leader>xC", "<cmd>XcodebuildShowCodeCoverageReport<cr>", desc = "Show Code Coverage Report" },
		{ "<leader>xe", "<cmd>XcodebuildTestExplorerToggle<cr>", desc = "Toggle Test Explorer" },
		{ "<leader>xs", "<cmd>XcodebuildFailingSnapshots<cr>", desc = "Show Failing Snapshots" },

		{ "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", desc = "Select Device" },
		{ "<leader>xp", "<cmd>XcodebuildSelectTestPlan<cr>", desc = "Select Test Plan" },
		{ "<leader>xq", "<cmd>Telescope quickfix<cr>", desc = "Show QuickFix List" },

		{ "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", desc = "Quickfix Line" },
		{ "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", desc = "Show Code Actions" },
	},
	config = function()
		require("xcodebuild").setup({
			-- put some options here or leave it empty to use default settings
			integrations = {
				pymobiledevice = {
					enabled = true,
				},
				netrw = {
					guess_target = false
				}
			},
			project_manager = {
				guess_target = false, -- guess target for the new file based on the file path
				find_xcodeproj = false, -- instead of using configured xcodeproj search for xcodeproj closest to targeted file
				should_update_project = function(path) -- path can lead to directory or file
					-- it could be useful if you mix Xcode project with SPM for example
					return true
				end
			}
		})
	end,
}
