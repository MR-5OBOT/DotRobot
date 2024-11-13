return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "hrsh7th/cmp-nvim-lsp", commit = "44b16d11215dce86f253ce0c30949813c0a90765" },
            { "SmiteshP/nvim-navic", commit = "0ffa7ffe6588f3417e680439872f5049e38a24db" },
            {
                "utilyre/barbecue.nvim",
                commit = "cd7e7da622d68136e13721865b4d919efd6325ed",
                dependencies = {
                    "SmiteshP/nvim-navic",
                    "nvim-tree/nvim-web-devicons",
                },
            },
        },
        config = function()
            local lspconfig = require("lspconfig")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            local navic = require("nvim-navic")

            -- Configure barbecue
            require("barbecue").setup({
                show_navic = true,
                attach_navic = true,
                theme = "auto",
                create_autocmd = false, -- Prevent multiple attach
            })

            -- Enhanced diagnostic configuration
            vim.diagnostic.config({
                virtual_text = {
                    prefix = "●",
                    source = "if_many",
                },
                float = {
                    source = "always",
                    border = "rounded",
                },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            -- Set up key mappings with better error handling
            local function setup_keymaps(bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }
                local mappings = {
                    ["gD"] = function() vim.lsp.buf.declaration() end,
                    ["gd"] = function() vim.lsp.buf.definition() end,
                    ["gi"] = function() vim.lsp.buf.implementation() end,
                    ["gr"] = function() vim.lsp.buf.references() end,
                    ["K"] = function() vim.lsp.buf.hover() end,
                    ["<leader>rn"] = function() vim.lsp.buf.rename() end,
                    ["<leader>ca"] = function() vim.lsp.buf.code_action() end,
                    ["<leader>d"] = function() vim.diagnostic.open_float() end,
                    ["[d"] = function() vim.diagnostic.goto_prev({ float = { border = "rounded" }}) end,
                    ["]d"] = function() vim.diagnostic.goto_next({ float = { border = "rounded" }}) end,
                }

                for k, v in pairs(mappings) do
                    pcall(vim.keymap.set, "n", k, v, opts)
                end
            end

            -- Enhanced LSP on_attach function
            local function on_attach(client, bufnr)
                setup_keymaps(bufnr)

                -- Attach navic if the server supports document symbols
                if client.server_capabilities.documentSymbolProvider then
                    navic.attach(client, bufnr)
                end

                -- Set autoformat if server supports it
                if client.server_capabilities.documentFormattingProvider then
                    local augroup = vim.api.nvim_create_augroup("LspFormatting_" .. bufnr, {})
                    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = augroup,
                        buffer = bufnr,
                        callback = function()
                            if vim.fn.getfsize(vim.api.nvim_buf_get_name(0)) > 1000000 then
                                return -- Skip files larger than 1MB
                            end
                            vim.lsp.buf.format({
                                async = false,
                                timeout_ms = 2000,
                                filter = function(c) return c.name == client.name end
                            })
                        end,
                    })
                end
            end

            -- Setup LSP servers with capabilities
            local capabilities = cmp_nvim_lsp.default_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            -- Define server configurations with error handling
            local servers = {
                -- Python
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "basic",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },
                -- Lua
                lua_ls = {
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = {
                                library = { vim.fn.stdpath("config") .. "/lua" },
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                        },
                    },
                },
                -- TypeScript/JavaScript
                tsserver = {
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "all",
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                        javascript = {
                            inlayHints = {
                                includeInlayParameterNameHints = "all",
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                    },
                },
                -- HTML
                html = {
                    settings = {
                        html = {
                            format = {
                                indentInnerHtml = true,
                                wrapLineLength = 120,
                                wrapAttributes = "auto",
                            },
                        },
                    },
                },
                -- CSS
                cssls = {
                    settings = {
                        css = {
                            validate = true,
                            lint = {
                                unknownAtRules = "ignore",
                            },
                        },
                    },
                },
            }

            -- Configure all servers with error handling
            for server, config in pairs(servers) do
                local success, _ = pcall(function()
                    lspconfig[server].setup(vim.tbl_deep_extend("force", {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        flags = {
                            debounce_text_changes = 150,
                        },
                    }, config))
                end)

                if not success then
                    vim.notify(string.format("Failed to setup %s", server), vim.log.levels.WARN)
                end
            end
        end,
    },
}
