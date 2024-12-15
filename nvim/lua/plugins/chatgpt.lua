return {
  "jackMort/ChatGPT.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "ChatGPT", "ChatGPTRun", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
  config = function()
    require("chatgpt").setup()
  end
}
