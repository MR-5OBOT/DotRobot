return {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {
        check_ts = true,                -- Enable treesitter
        ts_config = {
            lua = { "string" },         -- Don't add pairs in lua string treesitter nodes
            javascript = { "template_string" }, -- Don't add pairs in JavaScript template_string treesitter nodes
            java = false,               -- Don't check treesitter on Java
        },
    }                                   -- this is equalent to setup({}) function
}
