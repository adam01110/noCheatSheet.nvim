local api = vim.api
local genstr = string.rep
local strw = api.nvim_strwidth
local ch = require "nocheatsheet.cheatsheet"
local state = ch.state
local gapx = 10
local heading = {
  "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
  "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
}

return function(buf, win, action)
  action = action or "open"

  local ns = api.nvim_create_namespace "nocheatsheet"
  local win_w = api.nvim_win_get_width(0)

  if action == "open" then
    state.mappings_tb = ch.organize_mappings()
  else
    vim.bo[buf].ma = true
  end

  buf = buf or api.nvim_create_buf(false, true)
  win = win or api.nvim_get_current_win()

  api.nvim_set_current_win(win)

  -- Find largest string i.e mapping desc among all mappings
  local max_strlen = 0

  for _, section in pairs(state.mappings_tb) do
    for _, v in ipairs(section) do
      local curstrlen = strw(v[1]) + strw(v[2])
      max_strlen = max_strlen < curstrlen and curstrlen or max_strlen
    end
  end

  local box_w = max_strlen + gapx + 5

  local function addpadding(str)
    local pad = box_w - strw(str)
    local l_pad = math.floor(pad / 2)
    str = str:gsub("^%l", string.upper)
    return genstr(" ", l_pad) .. str .. genstr(" ", pad - l_pad)
  end

  local lines = {
    { genstr(" ", box_w), "NoCheatSheetAsciiHeader" },
    { addpadding(heading[1]), "NoCheatSheetAsciiHeader" },
    { addpadding(heading[2]), "NoCheatSheetAsciiHeader" },
    { genstr(" ", box_w), "NoCheatSheetAsciiHeader" },
    { "" },
  }

  local sections = vim.tbl_keys(state.mappings_tb)
  table.sort(sections)

  for _, name in ipairs(sections) do
    table.insert(lines, { addpadding(name), "NoCheatSheetHeading" })
    table.insert(lines, { genstr(" ", box_w), "NoCheatSheetSection" })

    for _, val in ipairs(state.mappings_tb[name]) do
      local pad = max_strlen - strw(val[1]) - strw(val[2]) + gapx
      local str = "  " .. val[1] .. genstr(" ", pad) .. val[2] .. "   "

      table.insert(lines, { str, "NoCheatSheetSection" })
      table.insert(lines, { genstr(" ", #str), "NoCheatSheetSection" })
    end

    table.insert(lines, { "" })
  end

  local start_col = math.max(math.floor(win_w / 2) - math.floor(box_w / 2), 0)
  local line_w = math.max(win_w, start_col + box_w + 1)

  -- make columns drawable
  for i = 1, #lines, 1 do
    api.nvim_buf_set_lines(buf, i, i, false, { string.rep(" ", line_w) })
  end

  for row, val in ipairs(lines) do
    local opts = { virt_text_pos = "overlay", virt_text = { val }, hl_mode = "replace" }
    api.nvim_buf_set_extmark(buf, ns, row, start_col, opts)
  end

  if action ~= "redraw" then
    api.nvim_set_current_buf(buf)
    ch.autocmds(buf)
  end
end
