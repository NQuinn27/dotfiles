return {
  "epwalsh/obsidian.nvim",
  config = function()
    require("obsidian").setup({
      use_advanced_uri = true,
      dir = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes",
      daily_notes = {
        folder = "daily",
      },
      completion = {
        nvim_cmp = true, -- if using nvim-cmp, otherwise set to false
      },
      note_id_func = function(title)
        return title
      end,
    })
    vim.keymap.set("n", "gf", function()
      if require("obsidian").util.cursor_on_markdown_link() then
        return "<cmd>ObsidianFollowLink<CR>"
      else
        return "gf"
      end
    end, { noremap = false, expr = true })
  end,
}
