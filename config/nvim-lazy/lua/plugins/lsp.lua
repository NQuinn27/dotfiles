return {
  "neovim/nvim-lspconfig",
  ---@class PluginLspOpts
  opts = {
    ---@type lspconfig.options
    servers = {
      cucumber_language_server = {
        cmd = { "cucumber-language-server", "--stdio" },
        root_dir = vim.fs.dirname(vim.fs.find(".git", { path = ".", upward = true })[1]),
        root_dir = require("lspconfig").util.find_git_ancestor,
        runtime = {
          version = "0.0.1",
          path = "cucumber-language-server",
        },
        settings = {
          cucumber = {
            features = { "features/**/*.feature", "ui/features/**/*.feature", "api/features/**/*.feature" },
            glue = { "src/**/*.ts", "ui/src/**/*.ts", "api/src/**/*.py" },
          },
        },
      },
      yamlls = {
        settings = {
          redhat = {
            telemetry = {
              enabled = false,
            },
          },
          yaml = {
            keyOrdering = false,
            format = {
              enable = true,
              proseWrap = "preserve",
              -- the key setting to prevent stripping newline at EOF:
              retainLineBreaks = true, -- <-- supported by yaml-language-server >= 1.15.0
            },
          },
        },
      },
    },
  },
}
