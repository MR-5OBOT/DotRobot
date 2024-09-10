
return {
    'lervag/vimtex',
    lazy = false,     -- we don't want to lazy load VimTeX
    ft = 'tex',  -- Load the plugin only for .tex files
    config = function()
        -- Basic settings
        vim.g.vimtex_view_method = 'zathura'  -- Change to your preferred PDF viewer
        vim.g.vimtex_mappings_enabled = 0  -- 1 Enable default mappings
        vim.g.vimtex_quickfix_mode = 0        -- Disable quickfix mode
        vim.g.vimtex_complete_enabled = 1     -- Enable completion
        vim.g.vimtex_indent_enabled = 1       -- Enable indentation
        vim.g.vimtex_syntax_enabled = 1       -- Enable syntax highlighting
        vim.g.vimtex_fold_enabled = 1         -- Enable folding
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

        -- Key mappings
        local map = function(mode, lhs, rhs)
            vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true, silent = true })
        end

        map('n', '<leader>ll', ':VimtexCompile<CR>')  -- Compile the document
        map('n', '<leader>lv', ':VimtexView<CR>')     -- View the document
        map('n', '<leader>le', ':VimtexErrors<CR>')   -- Show errors
        map('n', '<leader>lc', ':VimtexClean<CR>')    -- Clean auxiliary files
        map('n', '<leader>lt', ':VimtexTocToggle<CR>') -- Toggle the table of contents
        map('n', '<leader>lf', ':VimtexForward<CR>')  -- Forward search
        map('n', '<leader>lb', ':VimtexBackward<CR>') -- Backward search
        map('n', '<leader>li', ':VimtexInfo<CR>')     -- Show document info
    end,

}

