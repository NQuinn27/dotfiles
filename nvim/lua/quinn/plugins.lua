local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
  {'neovim/nvim-lspconfig'},
  {'hrsh7th/cmp-nvim-lsp'},
  {'hrsh7th/nvim-cmp'},
  {
    "williamboman/mason.nvim"
  },
  {'L3MON4D3/LuaSnip'},  {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- optional
    },
  },
  {
    "kdheepak/lazygit.nvim",
    -- optional for floating window border decoration
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim"
    },
  },
  {
    'akinsho/bufferline.nvim',
    tag = "*",
    dependencies = 'nvim-tree/nvim-web-devicons'
  },
  {
    'folke/noice.nvim',
    dependencies = {
      "rcarriga/nvim-notify"
    }
  },
  {
    "nvim-treesitter/nvim-treesitter", build = ":TSUpdate"
  },
  { -- Additional text objects via treesitter
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies ='nvim-treesitter',
  },
  'nvim-treesitter/nvim-treesitter-context',
  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  'lewis6991/gitsigns.nvim',
  'navarasu/onedark.nvim', -- Theme inspired by Atom
  'nvim-lualine/lualine.nvim', -- Fancier statusline
  'lukas-reineke/indent-blankline.nvim', -- Add indentation guides even on blank lines
  'numToStr/Comment.nvim', -- "gc" to comment visual regions/lines
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  -- Fuzzy Finder (files, lsp, etc)
  { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } },
  -- Fuzzy Finder Algorithm which dependencies local dependencies to be built. Only load if `make` is available
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = vim.fn.executable 'make' == 1 },
  'vim-airline/vim-airline',
  'vim-airline/vim-airline-themes',
  'vim-test/vim-test',
  'tpope/vim-rails',
  'https://github.com/RRethy/nvim-treesitter-endwise',
  'github/copilot.vim',
  'ThePrimeagen/harpoon',
  'epwalsh/obsidian.nvim',
  'simrat39/rust-tools.nvim',
  { "catppuccin/nvim", name = "catppuccin" },
  'folke/tokyonight.nvim',
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'projekt0n/github-nvim-theme' },
  { 'keith/swift.vim' },
  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup {} end
  },
  'https://tpope.io/vim/surround.git'
}

local opts = {}

require("lazy").setup(plugins, opts)
