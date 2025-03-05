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
		},
		config = function()
			vim.cmd("hi DapBreakpointColor guifg=#fa4848")
			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "⯈", texthl = "DapBreakpointColor", linehl = "", numhl = "" }
			)
		end,
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
			-- local mason_registry = require("mason-registry")
			-- local codelldb = mason_registry.get_package("codelldb") -- note that this will error if you provide a non-existent package name
			-- local codelldbpath = codelldb:get_install_path()
			-- --
			-- require("xcodebuild.integrations.dap").setup(codelldbpath)
			-- require("rustaceanvim.config").get_codelldb_adapter(codelldbPath, library_path)
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
