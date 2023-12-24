return {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
        require"toggleterm".setup {
        open_mapping = [[<C-\>]],
        close_on_exit = true, -- close the terminal window when the process exits
        start_in_insert = true,
        persist_size = true,
        float_opts = {
        border = 'curved',
        -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
        width = 70,
        height = 15,
        winblend = 1,
        },
        direction = 'float'
        }
end,
}
