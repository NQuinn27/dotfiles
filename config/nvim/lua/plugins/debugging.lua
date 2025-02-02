return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"suketa/nvim-dap-ruby",
			"leoluz/nvim-dap-go",
            "julianolf/nvim-dap-lldb",
			"wojciech-kulik/xcodebuild.nvim",
		},
		keys = {
			{
				"<leader>dt",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{ "<Leader>dx", ":DapTerminate<CR>", desc = "Terminate" },
			{ "<Leader>do", ":DapStepOver<CR>", desc = "Step over" },
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>db",
				function()
					require("xcodebuild.integrations.dap").build_and_debug()
				end,
				desc = "Xcode: Build and Debug",
				noremap = true,
			},
			{
				"<leader>dr",
				function()
					require("xcodebuild.integrations.dap").debug_without_build()
				end,
				desc = "Xcode: Debug Without Building",
			},
			{
				"<leader>dT",
				function()
					require("xcodebuild.integrations.dap").debug_tests()
				end,
				desc = "Xcode: Debug Tests",
			},
			{
				"<leader>b",
				function()
					require("xcodebuild.integrations.dap").toggle_breakpoint()
				end,
				desc = "Xcode: Toggle Breakpoint",
			},
			{
				"<leader>B",
				function()
					require("xcodebuild.integrations.dap").toggle_message_breakpoint()
				end,
				desc = "Xcode: Toggle Message Breakpoint",
			},
			{
				"<leader>dX",
				function()
					require("xcodebuild.integrations.dap").terminate_session()
				end,
				desc = "Xcode: Terminate Debugger",
			},
		},
		opts = function()
			local dap, dapui = require("dap"), require("dapui")
			require("dapui").setup()
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- Ruby
			require("dap-ruby").setup()

			-- Go
			require("dap-go").setup()

			-- Codelldb
			local codelldbPath = os.getenv("HOME") .. "/tools/codelldb-darwin-arm64/extension/adapter/codelldb"

			require("xcodebuild.integrations.dap").setup(codelldbPath)

            require("dap-lldb").setup()
		end,
	},
	-- which key integration
	{
		"folke/which-key.nvim",
		optional = true,
		opts = {
			defaults = {
				{ "<leader>d", group = "+debug" },
			},
		},
	},
}
