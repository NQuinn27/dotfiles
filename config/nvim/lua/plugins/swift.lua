return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "swift" })
    end,
  },

  -- {
  --   "williamboman/mason.nvim",
  --   optional = true,
  --   opts = function(_, opts)
  --     opts.ensure_installed = opts.ensure_installed or {}
  --     vim.list_extend(opts.ensure_installed, {
  --       "swiftlint", -- Required by nvim-lint swiftlint
  --       "swiftformat", -- Required by confirm.nvim swiftformat
  --       "xcbeautify", -- Required by xcodebuild.nvim
  --       "xcode-build-server" -- Required by nvim-lspconfig sourcekit
  --     })
  --   end,
  -- },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          root_dir = function(filename, _)
            local util = require("lspconfig.util")
            return util.root_pattern("buildServer.json")(filename)
              or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
              or util.find_git_ancestor(filename)
              or util.root_pattern("Package.swift")(filename)
          end,
        },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        swift = { "swiftlint" },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        swift = { "swiftformat" },
      },
    },
  },

  {
    "wojciech-kulik/xcodebuild.nvim",
    ft = { "swift", "objc", "objcpp" },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("xcodebuild").setup({
        code_coverage = {
          enabled = true,
        },
      })

      vim.keymap.set("n", "<leader>Xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
      vim.keymap.set("n", "<leader>Xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
      vim.keymap.set("n", "<leader>Xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
      vim.keymap.set("n", "<leader>Xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
      vim.keymap.set("n", "<leader>XT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
      vim.keymap.set("n", "<leader>XX", "<cmd>XcodebuildPicker<cr>", { desc = "Show All Xcodebuild Actions" })
      vim.keymap.set("n", "<leader>Xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
      vim.keymap.set("n", "<leader>Xp", "<cmd>XcodebuildSelectTestPlan<cr>", { desc = "Select Test Plan" })
      vim.keymap.set("n", "<leader>Xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code Coverage" })
      vim.keymap.set(
        "n",
        "<leader>XC",
        "<cmd>XcodebuildShowCodeCoverageReport<cr>",
        { desc = "Show Code Coverage Report" }
      )
      vim.keymap.set("n", "<leader>Xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
    end,
  },
}
