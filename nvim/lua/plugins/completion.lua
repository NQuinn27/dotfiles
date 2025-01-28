return {
    'saghen/blink.cmp',
    dependencies = {
        { 'rafamadriz/friendly-snippets' },
        {
            "saghen/blink.compat",
            optional = false,
            version = "*",
        }
    },
    version = '*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        keymap = { preset = 'default' },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono"
        },
        sources = {
            default = { 'lsp',
                'path',
                'snippets',
                'buffer',
            },
            per_filetype = {
                codecompanion = { "codecompanion" },
            },
        },
    },
    opts_extend = { "sources.default" },
    signature = { enabled = true }
}
