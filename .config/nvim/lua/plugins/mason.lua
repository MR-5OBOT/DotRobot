return {
  "williamboman/mason.nvim",
  dependencies = { "williamboman/mason-lspconfig.nvim" },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")

    -- Configure Mason UI icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- Set up LSP servers
    mason_lspconfig.setup({
      ensure_installed = {
        "ts_ls", "html", "cssls", "tailwindcss", "svelte",
        "lua_ls", "graphql", "emmet_ls", "prismals", "pyright",
        "clangd", "black",
      },
      automatic_installation = true,
    })
  end,
}
