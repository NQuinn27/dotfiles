return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
  },
  config = function()
    local lspconfig = require("lspconfig")
    lspconfig.lua_ls.setup({})
    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
    vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'LSP actions',
      callback = function(event)
        local opts = {buffer = event.buf}

        -- these will be buffer-local keybindings
        -- because they only work if you have an active language server

        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
      end
    })

    local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

    local default_setup = function(server)
      require('lspconfig')[server].setup({
        capabilities = lsp_capabilities,
      })
    end

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {},
      handlers = {
        default_setup,
        yamlls = function()
          lspconfig.yamlls.setup({
            settings = {
              yaml = {
                keyOrdering = false
              }
            }
          })
        end
      },
    })

    local cmp = require('cmp')
    cmp.setup({
      sources = {
        {name = 'nvim_lsp'},
      },
      mapping = cmp.mapping.preset.insert({
        -- Enter key confirms completion item
        ['<CR>'] = cmp.mapping.confirm({select = false}),

        -- Ctrl + space triggers completion menu
        ['<C-Space>'] = cmp.mapping.complete(),
      }),
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
    })

    vim.diagnostic.config({
      virtual_text = true
    })

    lspconfig.sourcekit.setup {
      cmd = { '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp' },
      settings = {
        sourcekit = {
          toolchain = '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain',
          buildFlags = { '-sdk',
            '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk' },
        },
      },
      capabilities = capabilities,
      on_attach = on_attach,
    }
  end
}
