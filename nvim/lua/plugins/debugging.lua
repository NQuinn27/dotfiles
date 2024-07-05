return {
	{
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"suketa/nvim-dap-ruby",
		"leoluz/nvim-dap-go",
	},
	keys = {
		{ "<leader>dt", "dap.toggle_breakpoint()", desc = "Toggle breakpoint" },
		{ "<Leader>dx", ":DapTerminate<CR>", desc = "Terminate" },
		{ "<Leader>do", ":DapStepOver<CR>", desc = "Step over" },
		{ "<leader>dc", "dap.continue()", desc = "Continue" },
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
	end,
},
	-- which key integration
	{
		"folke/which-key.nvim",
		optional = true,
		opts = {
			defaults = {
				["<leader>d"] = { name = "+debug" },
			},
		},
	}
}
