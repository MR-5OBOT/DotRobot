return {
  -- LSP configuration
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- Completion source for LSP
    "SmiteshP/nvim-navic",  -- For breadcrumb navigation
  },
  config = function()
    local lspconfig = require("lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local navic = require("nvim-navic")

    -- Set up key mappings
    local function setup_keymaps(bufnr)
      local opts = { noremap = true, silent = true, buffer = bufnr }
      local mappings = {
        gD = vim.lsp.buf.declaration,
        gd = vim.lsp.buf.definition,
        gi = vim.lsp.buf.implementation,
        K = vim.lsp.buf.hover,
        ["<leader>ca"] = vim.lsp.buf.code_action,
        ["<leader>d"] = vim.diagnostic.open_float,
        ["[d"] = vim.diagnostic.goto_prev,
        ["]d"] = vim.diagnostic.goto_next,
      }
      for k, v in pairs(mappings) do
        vim.keymap.set("n", k, v, opts)
      end
    end

    -- LSP on_attach function
    local function on_attach(client, bufnr)
      setup_keymaps(bufnr)
      -- Attach navic if the server supports document symbols
      if client.server_capabilities.documentSymbolProvider then
        navic.attach(client, bufnr)
      end
    end

    -- Setup LSP servers
    local capabilities = cmp_nvim_lsp.default_capabilities()
    local servers = { html = {}, pyright = {}, lua_ls = {}, clangd = {}, gopls = {} }

    for server, config in pairs(servers) do
      lspconfig[server].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end

    -- Configure barbecue
    require("barbecue").setup({
      show_navic = true, -- Show navigation using nvim-navic
      attach_navic = true,
    })
  end,
}
