return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    local header = {
  type = "text",
  val = {
    [[             o\             ]],
    [[   _________/__\__________  ]],
    [[  |                  - (  | ]],
    [[ ,'-.                 . `-| ]],
    [[(____".       ,-.    '   || ]],
    [[  |          /\,-\   ,-.  | ]],
    [[  |      ,-./     \ /'.-\ | ]],
    [[  |     /-.,\      /     \| ]],
    [[  |    /     \    ,-.     \ ]],
    [[  |___/_______\__/___\_____\]],
  },
  opts = {
    position = "center",
    hl = "Comment",
  },
}

local function getGreeting(name)
  local tableTime = os.date("*t")
  local hour = tableTime.hour
  local greetingsTable = {
    [1] = "  Sleep well",
    [2] = "  Good morning",
    [3] = "  Good afternoon",
    [4] = "  Good evening",
    [5] = "望 Good night",
  }
  local greetingIndex = 0
  if hour == 23 or hour < 7 then
    greetingIndex = 1
  elseif hour < 12 then
    greetingIndex = 2
  elseif hour >= 12 and hour < 18 then
    greetingIndex = 3
  elseif hour >= 18 and hour < 21 then
    greetingIndex = 4
  elseif hour >= 21 then
    greetingIndex = 5
  end
  return greetingsTable[greetingIndex] .. ", " .. name
end

local userName = "Emuel"
local greeting = getGreeting(userName)

local greetHeading = {
  type = "text",
  val = greeting,
  opts = {
    position = "center",
    hl = "String",
  },
}

local quote = "First, solve the problem. Then, write the code."

local quoteAuthor = "mr robot"
local fullQuote = quote .. "\n \n                  - " .. quoteAuthor

local fortune = {
  type = "text",
  val = fullQuote,
  opts = {
    position = "center",
    hl = "Comment",
  },
}

local function button(sc, txt, keybind)
  local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

  local opts = {
    position = "center",
    text = txt,
    shortcut = sc,
    cursor = 6,
    width = 30,
    align_shortcut = "right",
    hl_shortcut = "Number",
    hl = "Function",
  }
  if keybind then
    opts.keymap = { "n", sc_, keybind, { noremap = true, silent = true } }
  end

  return {
    type = "button",
    val = txt,
    on_press = function()
      local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
      vim.api.nvim_feedkeys(key, "normal", false)
    end,
    opts = opts,
  }
end

local buttons = {
  type = "group",
  val = {
    button("f", "   Search                ", ":Telescope find_files<CR>"),
    button("u", "   Update                ", ":Lazy sync<CR>"),
    button("c", "   Config                ", ":e ~/.config/nvim/<CR>"),
    button("q", "   Quit                  ", ":qa!<CR>"),
  },
  opts = {
    position = "center",
    spacing = 1,
  },
}

local section = {
  header = header,
  buttons = buttons,
  greetHeading = greetHeading,
  footer = fortune,
}

local opts = {
  layout = {
    { type = "padding", val = 1 },
    section.header,
    { type = "padding", val = 1 },
    section.greetHeading,
    { type = "padding", val = 1 },
    section.buttons,
    { type = "padding", val = 1 },
    section.footer,
  },
  opts = {
    margin = 44,
  },
}

alpha.setup(opts)  end,
}
