return {
  "christoomey/vim-tmux-navigator",
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate to left tmux pane" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate to right tmux pane" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate to down tmux pane" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate to up tmux pane" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous tmux pane" },
  },
}
