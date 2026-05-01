local api = vim.api
local new_cmd = api.nvim_create_user_command
local config = require "nocheatsheet.config"
local M = {}

local command_name
local augroup = api.nvim_create_augroup("NoCheatSheet", { clear = true })

local function get_hl(name)
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = name, link = false })
  return ok and hl or {}
end

local function fallback(value, default)
  return value and value > 0 and value or default
end

local function blend(fg, bg, alpha)
  local function channel(value, shift)
    return math.floor(value / 2 ^ shift) % 256
  end

  local r = math.floor(channel(fg, 16) * alpha + channel(bg, 16) * (1 - alpha))
  local g = math.floor(channel(fg, 8) * alpha + channel(bg, 8) * (1 - alpha))
  local b = math.floor(channel(fg, 0) * alpha + channel(bg, 0) * (1 - alpha))

  return r * 65536 + g * 256 + b
end

local function color(name, field, default)
  return fallback(get_hl(name)[field], default)
end

local function default_highlights()
  local normal = get_hl "Normal"
  local normal_fg = fallback(normal.fg, 0xd8dee9)
  local normal_bg = fallback(normal.bg, vim.o.background == "light" and 0xffffff or 0x101010)
  local section_bg = fallback(get_hl("NormalFloat").bg, blend(normal_fg, normal_bg, 0.08))

  return {
    NoCheatSheetAsciiHeader = { fg = color("Title", "fg", normal_fg), bg = section_bg, bold = true },
    NoCheatSheetSection = { fg = normal_fg, bg = section_bg },
    NoCheatSheetHeading = { fg = color("Function", "fg", normal_fg), bg = section_bg, bold = true },
    NoCheatSheetHeadblue = { fg = color("Identifier", "fg", 0x61afef), bg = section_bg, bold = true },
    NoCheatSheetHeadred = { fg = color("ErrorMsg", "fg", 0xe06c75), bg = section_bg, bold = true },
    NoCheatSheetHeadgreen = { fg = color("String", "fg", 0x98c379), bg = section_bg, bold = true },
    NoCheatSheetHeadyellow = { fg = color("WarningMsg", "fg", 0xe5c07b), bg = section_bg, bold = true },
    NoCheatSheetHeadorange = { fg = color("Number", "fg", 0xd19a66), bg = section_bg, bold = true },
    NoCheatSheetHeadbaby_pink = { fg = color("Special", "fg", 0xde98fd), bg = section_bg, bold = true },
    NoCheatSheetHeadpurple = { fg = color("Statement", "fg", 0xc678dd), bg = section_bg, bold = true },
    NoCheatSheetHeadwhite = { fg = normal_fg, bg = section_bg, bold = true },
    NoCheatSheetHeadcyan = { fg = color("Type", "fg", 0x56b6c2), bg = section_bg, bold = true },
    NoCheatSheetHeadvibrant_green = { fg = color("Constant", "fg", 0x7eca9c), bg = section_bg, bold = true },
    NoCheatSheetHeadteal = { fg = color("PreProc", "fg", 0x519aba), bg = section_bg, bold = true },
  }
end

local function set_highlights()
  for group, opts in pairs(default_highlights()) do
    api.nvim_set_hl(0, group, opts)
  end

  for group, opts in pairs(config.options.highlights) do
    if type(opts) == "string" then
      api.nvim_set_hl(0, group, { link = opts })
    else
      api.nvim_set_hl(0, group, opts)
    end
  end
end

local function create_autocmds()
  api.nvim_clear_autocmds { group = augroup }

  api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = set_highlights,
  })
end

local function create_command()
  if command_name and command_name ~= config.options.command then
    pcall(api.nvim_del_user_command, command_name)
  end

  command_name = config.options.command

  new_cmd(command_name, function()
    M.toggle()
  end, { force = true })
end

M.open = function()
  require("nocheatsheet.cheatsheet." .. config.options.theme)()
end

M.close = function()
  if vim.g.nocheatsheet_buf and api.nvim_buf_is_valid(vim.g.nocheatsheet_buf) then
    api.nvim_buf_delete(vim.g.nocheatsheet_buf, { force = true })
  end
end

M.toggle = function()
  if vim.g.nocheatsheet_displayed then
    M.close()
  else
    M.open()
  end
end

M.setup = function(opts)
  config.setup(opts)

  if not vim.tbl_contains({ "grid", "simple" }, config.options.theme) then
    error("nocheatsheet: invalid theme '" .. config.options.theme .. "'. Expected 'grid' or 'simple'.")
  end

  set_highlights()
  create_autocmds()
  create_command()

  return M
end

return M
