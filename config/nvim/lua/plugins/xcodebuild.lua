return {
  "wojciech-kulik/xcodebuild.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
  },
  config = function()
    require("xcodebuild").setup({
      -- put some options here or leave it empty to use default settings
      integrations = {
        pymobiledevice = {
          enabled = true,
        },
        netrw = {
          guess_target = false,
        },
      },
      project_manager = {
        guess_target = false, -- guess target for the new file based on the file path
        find_xcodeproj = false, -- instead of using configured xcodeproj search for xcodeproj closest to targeted file
        should_update_project = function(path) -- path can lead to directory or file
          -- it could be useful if you mix Xcode project with SPM for example
          return true
        end,
      },
    })
  end,
}
