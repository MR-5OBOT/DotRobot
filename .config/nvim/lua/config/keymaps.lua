---------------------------------------------------------------
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝

-----------------------------------------------
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set
local map = vim.api.nvim_set_keymap
------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
----------------------------------------------------------------------------------------------------------------
keymap("n", "<leader>/", "<C-W>v", { desc = "Split window right", remap = true })
keymap("n", "<C-c>", "<cmd>close<CR>", { desc = "Close Split window" })
keymap("n", "<leader>x", ":bd<CR>", {desc = "close buffer"})
----------------------------------------------------------------------------------------------------------------
keymap("i", "jk", "<ESC>", opts)                       -- Press jk fast to exit insert mode 
keymap("n", "L", "$", opts)                            -- easy go to end of line
keymap("n", "H", "^", opts)                            -- easy go to the start of line
keymap('n', 'r', '<C-r>')                              -- Faster redo
keymap('n', '<leader>ms', ':%s/')                      -- Easier multi select and remove
keymap("n", "<Enter>", "<cmd>nohlsearch<CR>", opts)    -- Clear search
----------------------------------------------------------------------------------------------------------------
keymap("n", "<leader>rn", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])	-- Rename
keymap("n", "<leader>mx", "<cmd>!chmod +x %<CR>", { desc = "Chmod +x without leaving document", silent = true })
keymap('n', '<leader>lw', function() vim.cmd('set wrap!') end, { desc = 'Toggle [w]rap' })
----------------------------------------------------------------------------------------------------------------
keymap('v', 'J', ":m '>+1<CR>gv=gv") -- move selected lines DOWN
keymap('v', 'K', ":m '<-2<CR>gv=gv") -- move selected lines UP
----------------------------------------------------------------------------------------------------------------
keymap("n", "<C-h>", "<C-w>h", opts) -- Better window navigation
keymap("n", "<C-j>", "<C-w>j", opts) -- Better window navigation
keymap("n", "<C-k>", "<C-w>k", opts) -- Better window navigation
keymap("n", "<C-l>", "<C-w>l", opts) -- Better window navigation
----------------------------------------------------------------------------------------------------------------
keymap("n", "j", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true }) -- Allow moving the cursor through wrapped lines
keymap("n", "k", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true }) -- Allow moving the cursor through wrapped lines
----------------------------------------------------------------------------------------------------------------
-- vim.keymap('n', '<C-a>', 'ggVG') -- selection all tex


-- ██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗    ███╗   ███╗ █████╗ ██████╗ ███████
-- ██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║██╔════╝    ████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║███████╗    ██╔████╔██║███████║██████╔╝███████
-- █╔═══╝  ██║     ██║   ██║██║   ██║██║██║╚██╗██║╚════██║    ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║███████║    ██║ ╚═╝ ██║██║  ██║██║     ███████
-- ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝

keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "find_files"})
keymap("n", "<leader>fl", "<cmd>Telescope live_grep<cr>", { desc = "live_grep_find_text"})
keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "find_buffers"})
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "find_help"})

keymap('n', '<TAB>', '<CMD>BufferLineCycleNext<CR>', { desc = "bufferNext"})
keymap('n', '<S-TAB>', '<CMD>BufferLineCyclePrev<CR>', { desc = "bufferPrev"})
keymap("n", "<leader>bx", "<CMD>BufferLinePickClose<CR>", { desc = "CloseBuffer"})


