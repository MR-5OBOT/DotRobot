---------------------------------------------------------------
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗ ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝

-----------------------------------------------
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set -- new
local map = vim.api.nvim_set_keymap -- old
------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

----------------------------------------------------------------------------------------------------------------
keymap("i", "jk", "<ESC>", opts)                       -- Press jk fast to exit insert mode 
keymap("n", "<Enter>", "<cmd>nohlsearch<CR>", opts)    -- Clear search
keymap("n", "<leader>mx", "<cmd>!chmod +x %<CR>", { desc = "Chmod +x without leaving document", silent = true })
keymap('n', '<TAB>', '<cmd>bnext<CR>', { noremap = true, silent = true, desc = 'Next buffer' })
keymap('n', '<S-Tab>', '<cmd>bprev<CR>', { noremap = true, silent = true, desc = 'Previous buffer' })
-- keymap("n", "<leader>x", ":bd<CR>", {desc = "close buffer"})

----------------------------------------------------------------------------------------------------------------
keymap('v', 'J', ":m '>+1<CR>gv=gv") -- move selected lines DOWN
keymap('v', 'K', ":m '<-2<CR>gv=gv") -- move selected lines UP
----------------------------------------------------------------------------------------------------------------
-- keymap("n", "<C-h>", "<C-w>h", opts) -- Better window navigation
-- keymap("n", "<C-j>", "<C-w>j", opts) -- Better window navigation
-- keymap("n", "<C-k>", "<C-w>k", opts) -- Better window navigation
-- keymap("n", "<C-l>", "<C-w>l", opts) -- Better window navigation
----------------------------------------------------------------------------------------------------------------
keymap("n", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true }) -- Allow moving the cursor through wrapped lines
keymap("n", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true }) -- Allow moving the cursor through wrapped lines
----------------------------------------------------------------------------------------------------------------
keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
----------------------------------------------------------------------------------------------------------------
keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "find_files"})
-- keymap("n", "<leader>fl", "<cmd>Telescope live_grep<cr>", { desc = "live_grep_find_text"})
-- keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "find_buffers"})
-- keymap("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "find_help"})
----------------------------------------------------------------------------------------------------------------
-- open zathura in the current file
keymap('n', '<leader>z', ':!zathura %<CR>', { noremap = true, silent = true })

----------------------------------------------------------------------------------------------------------------
-- keymap("n", "<leader>/", "<C-W>v", { desc = "Split window right", remap = true })
-- keymap("n", "<C-c>", "<cmd>close<CR>", { desc = "Close Split window" })
-- keymap('n', '<leader>ms', ':%s/', {desc = "multi select & replace"})                      -- Easier multi select and remove


