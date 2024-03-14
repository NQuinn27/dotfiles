return {
  "jackMort/ChatGPT.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  -- event = "VeryLazy",
  cmd = { "ChatGPT", "ChatGPTRun", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
  config = function()
    local home = vim.fn.expand("$HOME")
    require("chatgpt").setup({
      api_key_cmd = "op read op://Personal/openAINvim/credential --no-newline",
      -- api_key_cmd = "gpg --decrypt " .. home .. "/openAI.txt.gpg",
    })
  end,
}
