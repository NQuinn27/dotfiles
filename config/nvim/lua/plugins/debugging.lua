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
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Breakpoint Condition",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Run/Continue",
			},
			{
				"<leader>da",
				function()
					local args_string = vim.fn.input("Args: ")
					local args = vim.split(args_string, " ")
					require("dap").continue({ args = args })
				end,
				desc = "Run with Args",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>dg",
				function()
					require("dap").goto_()
				end,
				desc = "Go to Line (No Execute)",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dj",
				function()
					require("dap").down()
				end,
				desc = "Down",
			},
			{
				"<leader>dk",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dP",
				function()
					require("dap").pause()
				end,
				desc = "Pause",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					require("dap").session()
				end,
				desc = "Session",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
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
			local mason_registry = require("mason-registry")
			if mason_registry.is_installed("codelldb") then
				local codelldb_root = vim.fn.stdpath("data") .. "/mason/packages/codelldb"
				local codelldb_path = codelldb_root .. "/extension/adapter/codelldb"
				local liblldb_path = codelldb_root .. "/extension/lldb/lib/liblldb.dylib"
				require("xcodebuild.integrations.dap").setup(codelldb_path)
				vim.g.rustaceanvim = vim.g.rustaceanvim or {}
				vim.g.rustaceanvim.dap = {
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path),
				}
			end
			-- setup dap config by VsCode launch.json file
			local vscode = require("dap.ext.vscode")
			local json = require("plenary.json")
			vscode.json_decode = function(str)
				return vim.json.decode(json.json_strip_comments(str))
			end
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
