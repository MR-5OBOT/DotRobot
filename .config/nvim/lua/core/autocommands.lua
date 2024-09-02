local ag = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

-- Disable commenting new lines
vim.cmd('autocmd BufEnter * set formatoptions-=cro')
vim.cmd('autocmd BufEnter * setlocal formatoptions-=cro')

-- python formatting
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.py",
  callback = function()
    vim.opt.textwidth = 79
    vim.opt.colorcolumn = "79"
  end
})

-- javascript, css, lua, html formatting
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = {"*.js", "*.html", "*.css", "*.lua"},
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
  end
})

-- return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
      if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
        vim.cmd("normal! g`\"")
      end
    end
})

-- Autocompile and run
vim.api.nvim_create_augroup('compileAndRun', { clear = true })

-- LaTeX
vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = 'compileAndRun',
  pattern = { 'tex' },
  callback = function()
    vim.api.nvim_set_keymap(
      'n',
      '<Leader>c',
      ':w<CR>:split|:terminal!latexmk -pvc -f -verbose -file-line-error -synctex=1 -interaction=nonstopmode -pdf % <CR>',
      { noremap = true, silent = true }
    )
  end
})


