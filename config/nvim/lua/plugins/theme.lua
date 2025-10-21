return {
    -- {
    --     "maxmx03/solarized.nvim",
    --     lazy = true,
    --     priority = 1000,
    --     opts = {},
    -- },
    -- {
    --     "catppuccin/nvim",
    --     name = "catppuccin",
    --     lazy = true,
    --     priority = 1000,
    --     opts = {
    --         flavour = "frappe",
    --     },
    -- },
    {
        "f-person/auto-dark-mode.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            update_interval = 1000,
            set_dark_mode = function()
                vim.o.background = "dark"
                -- vim.cmd("colorscheme zenbones")
            end,
            set_light_mode = function()
                vim.o.background = "light"
                -- vim.cmd("colorscheme zenbones")
            end,
        },
    },
    -- {
    --     "zenbones-theme/zenbones.nvim",
    --     -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    --     -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    --     -- In Vim, compat mode is turned on as Lush only works in Neovim.
    --     dependencies = "rktjmp/lush.nvim",
    --     lazy = false,
    --     priority = 1000,
    --     -- you can set set configuration options here
    --     -- config = function()
    --     --     vim.g.zenbones_darken_comments = 45
    --     --     vim.cmd.colorscheme('zenbones')
    --     -- end
    -- }
    --
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            vim.cmd("colorscheme rose-pine")
        end
    }
}
