-- custom functions to replace plugings LOL

-- toogle a terminal buffer
vim.api.nvim_set_keymap('n', '<leader>t', ':lua ToggleTerm()<CR>', { noremap = true, silent = true })

function ToggleTerm()
  if vim.fn.bufwinnr('term://*') ~= -1 then
    vim.cmd('bdelete! term://*')
  else
    vim.cmd('terminal')
  end
end

-- function for making commands to open my newtrade template into new file
vim.api.nvim_create_user_command('NewTrade', function()
  local date = os.date("%Y-%m-%d")
  local filename = "trading-logs/2023/" .. date .. ".md"
  vim.cmd('edit ' .. filename)
  vim.cmd('silent! read templates/new-trade.md')
end, {})

-- Define the command to change the color scheme based on a parameter
vim.api.nvim_create_user_command('SetColorScheme', function(opts)
  local scheme = opts.args -- Get the color scheme argument
  if scheme and scheme ~= '' then
    -- Switch to the provided color scheme
    vim.cmd('colorscheme ' .. scheme)
  else
    print('Please provide a valid color scheme name.')
  end
end, {
  nargs = 1,          -- Requires exactly one argument (the color scheme name)
  complete = 'color', -- Provides autocompletion for available color schemes
})
