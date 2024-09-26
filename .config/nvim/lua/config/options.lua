-- Set options for Neovim
local opt = vim.opt

opt.clipboard = "unnamedplus" -- Use system clipboard
opt.number = true             -- Show absolute line numbers
opt.relativenumber = true     -- Show relative line numbers
opt.termguicolors = true      -- Enable true colors
opt.autoindent = true         -- Auto-indent new lines
opt.shiftwidth = 4            -- Indentation level
opt.tabstop = 4               -- Tab width
opt.expandtab = true          -- Use spaces instead of tabs
opt.ignorecase = true         -- Ignore case in search
opt.smartcase = true          -- Enable smart case search
opt.hlsearch = true           -- Highlight search matches
opt.splitbelow = true         -- Horizontal splits go below
opt.scrolloff = 10            -- Lines to keep above/below the cursor
opt.sidescrolloff = 8         -- Columns to keep left/right of the cursor
opt.splitright = true         -- Vertical splits go right
opt.updatetime = 300          -- Update time for CursorHold
opt.backup = false            -- Disable backups
opt.undofile = true           -- Enable persistent undo
opt.history = 100             -- Command history size
opt.linebreak = true          -- Don't split words when wrapping
opt.wrap = false              -- Disable line wrapping
opt.cmdheight = 2             -- Command line height
opt.cursorline = true         -- Highlight current line
opt.fileencoding = "utf-8"    -- File encoding
-- opt.lazyredraw = true           -- Improve performance during redraw


-- Disable built-in plugins
vim.g.loaded_netrw = 1       -- Disable Netrw
vim.g.loaded_netrwPlugin = 1 -- Disable Netrw plugin
vim.g.loaded_2html_plugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_zip = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_vimball = 1
