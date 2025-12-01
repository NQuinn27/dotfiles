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
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc = "Toggle Breakpoint" },
            { "<leader>dc", function() require("dap").continue() end,                                             desc = "Run/Continue" },
            { "<leader>da", function()
                local args_string = vim.fn.input('Args: ')
                local args = vim.split(args_string, " ")
                require("dap").continue({ args = args })
            end, desc = "Run with Args" },
            { "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc = "Run to Cursor" },
            { "<leader>dg", function() require("dap").goto_() end,                                                desc = "Go to Line (No Execute)" },
            { "<leader>di", function() require("dap").step_into() end,                                            desc = "Step Into" },
            { "<leader>dj", function() require("dap").down() end,                                                 desc = "Down" },
            { "<leader>dk", function() require("dap").up() end,                                                   desc = "Up" },
            { "<leader>dl", function() require("dap").run_last() end,                                             desc = "Run Last" },
            { "<leader>do", function() require("dap").step_out() end,                                             desc = "Step Out" },
            { "<leader>dO", function() require("dap").step_over() end,                                            desc = "Step Over" },
            { "<leader>dP", function() require("dap").pause() end,                                                desc = "Pause" },
            { "<leader>dr", function() require("dap").repl.toggle() end,                                          desc = "Toggle REPL" },
            { "<leader>ds", function() require("dap").session() end,                                              desc = "Session" },
            { "<leader>dt", function() require("dap").terminate() end,                                            desc = "Terminate" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc = "Widgets" },
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
