-- Xcodebuild keymaps for Swift files
vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show Xcodebuild Actions", buffer = true })
vim.keymap.set(
	"n",
	"<leader>xf",
	"<cmd>XcodebuildProjectManager<cr>",
	{ desc = "Show Project Manager Actions", buffer = true }
)

vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project", buffer = true })
vim.keymap.set("n", "<leader>xB", "<cmd>XcodebuildBuildForTesting<cr>", { desc = "Build For Testing", buffer = true })
vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project", buffer = true })

vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests", buffer = true })
vim.keymap.set("v", "<leader>xt", "<cmd>XcodebuildTestSelected<cr>", { desc = "Run Selected Tests", buffer = true })
vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run Current Test Class", buffer = true })
vim.keymap.set("n", "<leader>x.", "<cmd>XcodebuildTestRepeat<cr>", { desc = "Repeat Last Test Run", buffer = true })

vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs", buffer = true })

vim.keymap.set("n", "<leader>db", function()
	require("xcodebuild.integrations.dap").build_and_debug()
end, { desc = "Xcode: Build and Debug", buffer = true, noremap = true })

vim.keymap.set("n", "<leader>dr", function()
	require("xcodebuild.integrations.dap").debug_without_build()
end, { desc = "Xcode: Debug Without Building", buffer = true })

vim.keymap.set("n", "<leader>dT", function()
	require("xcodebuild.integrations.dap").debug_tests()
end, { desc = "Xcode: Debug Tests", buffer = true })

vim.keymap.set("n", "<leader>b", function()
	require("xcodebuild.integrations.dap").toggle_breakpoint()
end, { desc = "Xcode: Toggle Breakpoint", buffer = true })

vim.keymap.set("n", "<leader>B", function()
	require("xcodebuild.integrations.dap").toggle_message_breakpoint()
end, { desc = "Xcode: Toggle Message Breakpoint", buffer = true })

vim.keymap.set("n", "<leader>dX", function()
	require("xcodebuild.integrations.dap").terminate_session()
end, { desc = "Xcode: Terminate Debugger", buffer = true })
