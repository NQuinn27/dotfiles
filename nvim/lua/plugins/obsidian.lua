return {
  "epwalsh/obsidian.nvim",
  config = function()
    require("obsidian").setup({
      use_advanced_uri = true,
      dir = "~/Documents/Notes",
      ft = "markdown",
      daily_notes = {
        folder = "Daily",
        date_format = "%Y/%m-%b/%Y-%m-%d",
        template = "T_Daily.md"
      },
      templates = {
        subdir = "Z_Templates",
      },
      completion = {
        nvim_cmp = true, -- if using nvim-cmp, otherwise set to false
      },
      note_id_func = function(title)
        return title
      end,
    })
    -- vim.opt.conceallevel = 1
    vim.keymap.set("n", "gf", function()
      if require("obsidian").util.cursor_on_markdown_link() then
        return "<cmd>ObsidianFollowLink<CR>"
      else
        return "gf"
      end
    end, { noremap = false, expr = true })
  end,
}
