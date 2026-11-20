-- Copy mode's own small nvim config (workflow.conf: Prefix+[ runs nvim -u this file).
-- Skips the full nvim config (plugins, lazy.nvim), so the overlay opens ~30-40 ms sooner.
-- Your options + colorscheme still load, so it looks and searches like your nvim.
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/kitty-scrollback.nvim")
require("config.options")
vim.cmd.colorscheme("mr5obot-theme")

-- y / Y copy to the clipboard and close, like tmux's copy-pipe-and-cancel. The plugin
-- only closes on yanks to "+", and a plain y would open its paste window instead.
vim.keymap.set({ "n", "v" }, "y", '"+y')
vim.keymap.set({ "n", "v" }, "Y", '"+Y')
require("kitty-scrollback").setup({
	{ paste_window = { yank_register_enabled = false } },
})
