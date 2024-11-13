return {
    {
        "williamboman/mason.nvim",
        event = "VeryLazy",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            local mason = require("mason")
            local mason_lspconfig = require("mason-lspconfig")
            local mason_tool_installer = require("mason-tool-installer")

            -- Configure Mason
            mason.setup({
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                    keymaps = {
                        toggle_package_expand = "<CR>",
                        install_package = "i",
                        update_package = "u",
                        uninstall_package = "x",
                        cancel_installation = "<C-c>",
                    },
                },
                max_concurrent_installers = 4,
                pip = {
                    upgrade_pip = true,
                },
            })

            -- Configure required LSP servers
            mason_lspconfig.setup({
                ensure_installed = {
                    "ts_ls",
                    "html",
                    "cssls",
                    "pyright",
                    "lua_ls",
                },
                automatic_installation = true,
            })

            -- Configure additional tools
            mason_tool_installer.setup({
                ensure_installed = {
                    -- Formatters
                    "prettier",
                    "stylua",
                    "black",
                    "isort",
                    -- Linters
                    "eslint_d",
                    "flake8",
                    "luacheck",
                },
                auto_update = true,
                run_on_start = true,
            })
        end,
    },
}
