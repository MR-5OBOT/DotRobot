return {
  "neovim/nvim-lspconfig",  -- LSP configuration plugin for Neovim
  event = { "BufReadPre", "BufNewFile" },  -- Load this plugin on buffer read or new file
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",  -- Completion source for Neovim's built-in LSP
    { "antosha417/nvim-lsp-file-operations", config = true },  -- File operations for LSP
  },
  config = function()
    local lspconfig = require("lspconfig")  -- Import the LSP configuration module
    local cmp_nvim_lsp = require("cmp_nvim_lsp")  -- Import completion capabilities
    local keymap = vim.keymap  -- Shorten the keymap reference

    local opts = { noremap = true, silent = true }  -- Keymap options for non-recursive and silent

    -- Function to attach LSP features to the buffer
    local on_attach = function(client, bufnr)
      opts.buffer = bufnr  -- Set buffer options for keymaps

      -- Keybindings for LSP functionality
      local mappings = {
        gR = "<cmd>Telescope lsp_references<CR>",  -- Show references to the symbol under the cursor
        gD = vim.lsp.buf.declaration,  -- Go to the declaration of the symbol
        gd = "<cmd>Telescope lsp_definitions<CR>",  -- Show definitions of the symbol
        gi = "<cmd>Telescope lsp_implementations<CR>",  -- Show implementations of the symbol
        gt = "<cmd>Telescope lsp_type_definitions<CR>",  -- Show type definitions of the symbol
        ["<leader>ca"] = vim.lsp.buf.code_action,  -- Show available code actions
        ["<leader>D"] = "<cmd>Telescope diagnostics bufnr=0<CR>",  -- Show diagnostics for the current buffer
        ["<leader>d"] = vim.diagnostic.open_float,  -- Show diagnostics in a floating window
        ["[d"] = vim.diagnostic.goto_prev,  -- Jump to the previous diagnostic
        ["]d"] = vim.diagnostic.goto_next,  -- Jump to the next diagnostic
        K = vim.lsp.buf.hover,  -- Show hover documentation for the symbol under the cursor
        ["<leader>rs"] = ":LspRestart<CR>",  -- Restart the LSP server
      }

      -- Set keybindings for LSP functionality
      for k, v in pairs(mappings) do
        keymap.set("n", k, v, opts)  -- Map each keybinding in normal mode
      end
    end

    -- Enable autocompletion capabilities for LSP
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Define diagnostic symbols for the sign column
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      vim.fn.sign_define("DiagnosticSign" .. type, { text = icon, texthl = "DiagnosticSign" .. type, numhl = "" })
    end

    -- Language server configurations
    local servers = {
      html = {},  -- HTML language server
      tsserver = {},  -- TypeScript language server
      cssls = {},  -- CSS language server
      tailwindcss = {},  -- Tailwind CSS language server
      svelte = {},  -- Svelte language server
      prismals = {},  -- Prisma ORM language server
      graphql = { filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" } },  -- GraphQL language server
      emmet_ls = { filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" } },  -- Emmet language server
      pyright = { filetypes = { "python" } },  -- Python language server
      lua_ls = {  -- Lua language server configuration
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },  -- Recognize 'vim' as a global variable
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,  -- Include Neovim runtime files
                [vim.fn.stdpath("config") .. "/lua"] = true,  -- Include user configuration files
              },
            },
          },
        },
      },
      clangd = {},  -- C/C++ language server
    }

    -- Setup each language server with capabilities and on_attach function
    for server, config in pairs(servers) do
      lspconfig[server].setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = on_attach,
      }, config))
    end

    -- Additional setup for Svelte to notify on file changes
    lspconfig["svelte"].setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)  -- Call the on_attach function
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.js", "*.ts" },  -- Trigger on JavaScript/TypeScript file save
          callback = function(ctx)
            if client.name == "svelte" then
              client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })  -- Notify the Svelte server of file changes
            end
          end,
        })
      end,
    })
  end,
}


