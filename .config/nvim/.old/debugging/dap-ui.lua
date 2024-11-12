return {
    'rcarriga/nvim-dap-ui',
    requires = { 'mfussenegger/nvim-dap' },
    config = function()
        local dapui = require("dapui")
        dapui.setup()

        -- Bind keymap to toggle the UI
        vim.keymap.set('n', '<Leader>du', function() dapui.toggle() end)

        -- Auto open and close DAP UI during debugging sessions
        local dap = require('dap')
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end
}
