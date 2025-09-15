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
            features = { "features/**/*.feature" },
            glue = { "src/**/*.ts" },
          },
        },
      },
    },
  },
}
