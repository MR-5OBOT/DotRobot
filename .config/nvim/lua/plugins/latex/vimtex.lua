return {
    {
  "lervag/vimtex",
  lazy = false,     -- we don't want to lazy load VimTeX
  init = function()
            -- VimTeX settings
            vim.g.vimtex_view_method = "zathura"  -- Change this to your preferred PDF viewer
            vim.g.vimtex_quickfix_mode = 0  -- Disable quickfix window
            vim.g.vimtex_indent_enabled = 1  -- Enable indentation
            vim.g.vimtex_syntax_enabled = 1  -- Enable syntax highlighting
            vim.g.vimtex_mappings_enabled = 1  -- Enable default mappings
            vim.g.vimtex_log_ignore = { "Underfull", "Overfull" }  -- Ignore specific log messages

            -- Compiler configuration
            vim.g.vimtex_compiler_latexmk = {
                build_dir = "Output",  -- Set output directory for latexmk
                callback = 1,
                continuous = 1,
                executable = "latexmk",
                options = {
                    "-pdf",
                    "-pdflatex='pdflatex -interaction=nonstopmode'",
                    "-silent",
                },
            }

            -- LSP configuration for LaTeX
            local lspconfig = require("lspconfig")
            lspconfig.texlab.setup {}

            -- Autocompletion setup
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)  -- For `vsnip` users.
                    end,
                },
                mapping = {
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.close(),
                    ["<CR>"] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "vsnip" },  -- For vsnip users.
                    { name = "path" },
                    { name = "buffer" },
                },
            })
        end,
    },
}

