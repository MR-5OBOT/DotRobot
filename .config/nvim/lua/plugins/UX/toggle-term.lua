return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function ()
  require("toggleterm").setup ({
   -- size can be a number or function which is passed the current terminal
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.4
    end
  end,

  open_mapping = [[<C-\>]],
  autochdir = true, -- when neovim changes it current directory the terminal will change it's own when next it's opened
  close_on_exit = true, -- close the terminal window when the process exits
  start_in_insert = true,
  direction = 'horizontal',
  auto_scroll = true, -- automatically scroll to the bottom on terminal output

  float_opts = {
        border = 'single',
        -- width = 90,
        -- height = 10,
        },
})

end,
}



