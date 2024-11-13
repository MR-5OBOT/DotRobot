return {
    {
        "jose-elias-alvarez/null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason.nvim",
            "jay-babu/mason-null-ls.nvim", -- Add this dependency
        },
        config = function()
            local null_ls = require("null-ls")
            local formatting = null_ls.builtins.formatting
            local diagnostics = null_ls.builtins.diagnostics
            local code_actions = null_ls.builtins.code_actions

            -- Setup mason-null-ls first
            require("mason-null-ls").setup({
                ensure_installed = {
                    "prettier",
                    "stylua",
                    "black",
                    "isort",
                    "eslint_d",
                    "flake8",
                },
                automatic_installation = true,
            })

            -- Utility function to check file size before formatting
            local function check_file_size(utils)
                local file_path = vim.api.nvim_buf_get_name(0)
                local file_size = vim.fn.getfsize(file_path)
                return file_size < 1000000 -- Skip files larger than 1MB
            end

            -- Configure null-ls
            null_ls.setup({
                debug = false,
                sources = {
                    -- Formatting
                    formatting.prettier.with({
                        extra_args = {
                            "--single-quote",
                            "--jsx-single-quote",
                            "--arrow-parens=avoid",
                        },
                        timeout = 7000,
                        condition = check_file_size,
                    }),
                    formatting.stylua.with({
                        extra_args = {
                            "--column-width=120",
                            "--indent-type=spaces",
                            "--indent-width=4",
                        },
                        condition = check_file_size,
                    }),
                    formatting.black.with({
                        extra_args = { "--line-length=120" },
                        condition = check_file_size,
                    }),
                    formatting.isort.with({
                        extra_args = { "--profile", "black" },
                        condition = check_file_size,
                    }),

                    -- Diagnostics
                    diagnostics.eslint_d.with({
                        condition = function(utils)
                            return utils.root_has_file({
                                ".eslintrc.js",
                                ".eslintrc.cjs",
                                ".eslintrc.json",
                            })
                        end,
                        timeout = 5000,
                    }),
                    diagnostics.flake8.with({
                        extra_args = { "--max-line-length", "120" },
                    }),

                    -- Code Actions
                    code_actions.gitsigns,
                    code_actions.eslint_d,
                },
                -- Setup on_attach function
                on_attach = function(client, bufnr)
                    -- Create format keymap
                    vim.keymap.set("n", "<leader>f", function()
                        vim.lsp.buf.format({
                            async = false,
                            timeout_ms = 2000,
                            filter = function(c)
                                return c.name == "null-ls"
                            end,
                        })
                    end, { buffer = bufnr, desc = "Format buffer" })

                    -- Setup autoformatting
                    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
                    if client.supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                local file_path = vim.api.nvim_buf_get_name(0)
                                if vim.fn.getfsize(file_path) > 1000000 then
                                    return -- Skip files larger than 1MB
                                end
                                vim.lsp.buf.format({
                                    async = false,
                                    timeout_ms = 2000,
                                    filter = function(c)
                                        return c.name == "null-ls"
                                    end,
                                })
                            end,
                        })
                    end
                end,
            })
        end,
    },
}

