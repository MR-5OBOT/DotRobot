-- Boyd Kelly
-- oxocarbon theme for lualine status
-- MIT license, see LICENSE for more details.
-- stylua: ignore

--visual magneta
--insert red (lighter)
--command green
--normal light blue

local colors = {
  color3 = '#101010',
  color1 = '#78a9ff',
  color2 = '#E55090',
  color6 = '#42be65',
  color7 = '#ee5396',
  color8 = '#3ddbd9',
  color9 = '#dde1e6',
  color10 = '#8F70C0'
}

return {
  replace = {
    a = { fg = colors.color3, bg = colors.color7 },
    b = { fg = colors.color2, bg = colors.color3 },
  },
  inactive = {
    a = { fg = colors.color3, bg = colors.color1 },
    b = { fg = colors.color9, bg = colors.color3 },
    z = { fg = colors.color3, bg = colors.color3 },
  },
  normal = {
    a = { fg = colors.color3, bg = colors.color10 },
    b = { fg = colors.color9, bg = colors.color3 },
    c = { fg = colors.color9, bg = colors.color3 },
    z = { fg = colors.color9, bg = colors.color3 },
  },
  visual = {
    a = { fg = colors.color3, bg = colors.color6 },
    b = { fg = colors.color9, bg = colors.color3 },
    y = { fg = colors.color9, bg = colors.color3 },
    z = { fg = colors.color7, bg = colors.color3 },
  },
  insert = {
    a = { fg = colors.color3, bg = colors.color8 },
    b = { fg = colors.color9, bg = colors.color3 },
    z = { fg = colors.color8, bg = colors.color3 },
  },
  command = {
    a = { fg = colors.color3, bg = colors.color2 },
  },
}
