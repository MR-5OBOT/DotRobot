return {
  "nyoom-engineering/oxocarbon.nvim",
		lazy = false,
    priority = 999, -- make sure to load this before all the other start plugins
		config = function()
      vim.cmd.colorscheme("oxocarbon")
	    vim.opt.background = "dark"
			-- vim.cmd("highlight FloatBorder guifg=#202020")
		end,
}

