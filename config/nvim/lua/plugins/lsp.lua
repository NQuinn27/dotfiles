return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      sourcekit = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
      },
      cucumber_language_server = {
        cmd = { "cucumber-language-server", "--stdio" },
        root_dir = vim.fs.dirname(vim.fs.find(".git", { path = ".", upward = true })[1]),
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
