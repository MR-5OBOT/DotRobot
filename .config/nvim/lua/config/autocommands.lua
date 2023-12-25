-- local ag = vim.api.nvim_create_augroup
-- local au = vim.api.nvim_create_autocmd

-- Disable commenting new lines
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')

