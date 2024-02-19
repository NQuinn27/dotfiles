return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"suketa/nvim-dap-ruby",
		"leoluz/nvim-dap-go",
	},

	config = function()
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

		vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, {})
		vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>")
		vim.keymap.set("n", "<Leader>do", ":DapStepOver<CR>")
		vim.keymap.set("n", "<leader>dc", dap.continue, {})
	end,
}
