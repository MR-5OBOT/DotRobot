return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.5
                end
            end,

            open_mapping = [[<C-\>]],
            autochdir = true,
            close_on_exit = true,
            start_in_insert = true,
            direction = 'float',
            auto_scroll = true,

        })
    end,
}
