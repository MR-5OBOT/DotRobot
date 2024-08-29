

-- function for making commands to open my newtrade template into new file
vim.api.nvim_create_user_command('NewTrade', function()
    local date = os.date("%Y-%m-%d")
    local filename = "trading-logs/2023/" .. date .. ".md"
    vim.cmd('edit ' .. filename)
    vim.cmd('silent! read templates/new-trade.md')
end, {})

