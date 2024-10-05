local M = {}

function M.setup()
  -- Define your highlights
  local highlights = {
    MyTabLine = { fg = '#ffffff', bg = '#B33E70' },     -- Inactive tab color
    MyTabLineSel = { fg = '#ffffff', bg = '#6F5796' },  -- Active tab color
    MyTabLineFill = { fg = '#ffffff', bg = '#101010' }, -- Background color
  }

  -- Set the tabline configuration
  require('tabby.tabline').set(function(line)
    return {
      {
        { '  ', hl = highlights.MyTabLine },
        line.sep('', highlights.MyTabLine, highlights.MyTabLineFill),
      },
      line.tabs().foreach(function(tab)
        local hl = tab.is_current() and highlights.MyTabLineSel or highlights.MyTabLine
        return {
          line.sep('', hl, highlights.MyTabLineFill),
          tab.is_current() and ' ' or ' ',
          tab.number(),
          tab.name(),
          line.sep('', hl, highlights.MyTabLineFill),
          hl = hl,
          margin = ' ',
        }
      end),
      line.spacer(),
      {
        line.sep('', highlights.MyTabLine, highlights.MyTabLineFill),
        { '  ', hl = highlights.MyTabLine },
      },
      hl = highlights.MyTabLineFill,
    }
  end)
end

return {
  'nanozuki/tabby.nvim',
  lazy = true,
  event = 'VeryLazy',
  config = M.setup,
}
