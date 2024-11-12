return {
    'mfussenegger/nvim-dap-python',
    config = function()
        -- Setup dap-python with the path to the python interpreter (adjust if needed)
        require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')

        -- Optionally bind specific keymaps for Python debugging
        vim.keymap.set('n', '<Leader>dn', function() require('dap-python').test_method() end)
        vim.keymap.set('n', '<Leader>df', function() require('dap-python').test_class() end)
    end
}
