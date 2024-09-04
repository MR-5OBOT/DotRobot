return {
  "NvChad/nvim-colorizer.lua",
  lazy = false,
  event = { "BufReadPre", "BufNewFile" },
  config = function ()
    require("colorizer").setup({
	filetypes = { "*" },
	user_default_options = {
		RGB = true,
		RRGGBB = true,
		names = true,
		RRGGBBAA = true,
		AARRGGBB = true,
		rgb_fn = true,
		hsl_fn = true,
		css = true,
		css_fn = true,
    -- Available modes for `mode`: foreground, background,  virtualtext
    mode = "background", -- Set the display mode.
		tailwind = true,
		sass = { enable = true, parsers = { "css" }, },
		virtualtext = "■",
		always_update = false
	},
	buftypes = {"*"},
})
  end
}
