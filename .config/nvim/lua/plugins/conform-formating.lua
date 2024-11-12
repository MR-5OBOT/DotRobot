return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")
        conform.setup({
            formatters_by_ft = {
                html = { "prettier" },
                css = { "prettier" },
                javascript = { "prettier" },
                json = { "prettier" },
                python = { "black" },
                lua = { "stylua" },          -- Use Stylua for Lua formatting
                go = { "gofmt" },            -- Use gofmt for Go formatting
                -- markdown = { "prettier" },   -- Use prettier for Markdown formatting
                ruby = { "rufo" },           -- Use Rufo for Ruby formatting
                yaml = { "prettier" },       -- Use prettier for YAML formatting
                typescript = { "prettier" }, -- Use prettier for TypeScript formatting
                php = { "phpcsfixer" },      -- Use PHP-CS-Fixer for PHP formatting
            },
            format_on_save = {
                lsp_fallback = true,
                async = false,
                timeout_ms = 500,
            },
        })
    end,
}
