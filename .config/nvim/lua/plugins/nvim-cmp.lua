return {
  "hrsh7th/nvim-cmp",  -- Main completion plugin
  event = "InsertEnter",  -- Load on entering insert mode
  dependencies = {
    "hrsh7th/cmp-buffer",  -- Source for text in buffer
    "hrsh7th/cmp-path",  -- Source for file system paths
    -- "hrsh7th/cmp-cmdline",  -- Source for command line completion
    "L3MON4D3/LuaSnip",  -- Snippet engine
    "saadparwaiz1/cmp_luasnip",  -- For autocompletion with LuaSnip
    "rafamadriz/friendly-snippets",  -- Useful snippets
    "onsails/lspkind.nvim",  -- VS Code-like pictograms
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    -- Load VS Code style snippets from installed plugins (e.g., friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    -- Icons for completion items
    local kind_icons = {
      Text = "",
      Method = "m",
      Function = "",
      Constructor = "",
      Field = "",
      Variable = "",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "",
      Event = "",
      Operator = "",
      TypeParameter = "",
    }

    -- Setup nvim-cmp
    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noinsert,noselect",  -- Completion options
        -- pumblend = 20,  -- Transparency of the completion menu
      },
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)  -- Expand snippets
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),  -- Previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(),  -- Next suggestion
        ["<C-Space>"] = cmp.mapping.complete(),  -- Show completion suggestions
        ["<C-x>"] = cmp.mapping.abort(),  -- Close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),  -- Confirm selection
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },  -- LSP completion
        { name = "luasnip" },  -- Snippets
        { name = "buffer" },  -- Text within current buffer
        { name = "path" },  -- File system paths
      }),
      formatting = {
        format = lspkind.cmp_format({
          with_text = true,  -- Show icons alongside text
          maxwidth = 50,  -- Max width of completion menu
          ellipsis_char = "...",  -- Ellipsis character for overflow
          menu = {
            nvim_lsp = "[LSP]",
            luasnip = "[Snippet]",
            buffer = "[Buffer]",
            path = "[Path]",
          },
        }),
      },
    })

    -- Setup command line completion
    cmp.setup.cmdline(':', {
      sources = {
        { name = 'cmdline' },  -- Command line completion
      },
    })

    -- Setup command line completion for '/'
    cmp.setup.cmdline('/', {
      sources = {
        { name = 'buffer' },  -- Buffer completion for search
      },
    })
  end,
}
