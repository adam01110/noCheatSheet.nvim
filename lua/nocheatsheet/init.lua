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

local function luminance(value)
  local r = math.floor(value / 65536) % 256
  local g = math.floor(value / 256) % 256
  local b = value % 256

  return (0.299 * r + 0.587 * g + 0.114 * b) / 255
end

local function normalize_chip_bg(bg, normal_fg)
  if vim.o.background == "dark" and luminance(bg) < 0.48 then
    return blend(normal_fg, bg, 0.35)
  end

  return bg
end

local function color(name, field, default)
  return fallback(get_hl(name)[field], default)
end

local function default_highlights()
  local normal = get_hl "Normal"
  local normal_fg = fallback(normal.fg, 0xd8dee9)
  local normal_bg = fallback(normal.bg, vim.o.background == "light" and 0xffffff or 0x101010)
  local section_bg = fallback(get_hl("NormalFloat").bg, blend(normal_fg, normal_bg, 0.10))
  if section_bg == normal_bg then
    section_bg = blend(normal_fg, normal_bg, 0.10)
  end

  local chip_fg = vim.o.background == "light" and normal_fg or normal_bg
  local blue = normalize_chip_bg(color("Identifier", "fg", 0x61afef), normal_fg)
  local red = normalize_chip_bg(color("ErrorMsg", "fg", 0xe06c75), normal_fg)
  local green = normalize_chip_bg(color("String", "fg", 0x98c379), normal_fg)
  local yellow = normalize_chip_bg(color("WarningMsg", "fg", 0xe5c07b), normal_fg)
  local orange = normalize_chip_bg(color("Number", "fg", 0xd19a66), normal_fg)
  local baby_pink = normalize_chip_bg(color("Special", "fg", 0xde98fd), normal_fg)
  local purple = normalize_chip_bg(color("Statement", "fg", 0xc678dd), normal_fg)
  local white = normalize_chip_bg(color("Normal", "fg", normal_fg), normal_fg)
  local cyan = normalize_chip_bg(color("Type", "fg", 0x56b6c2), normal_fg)
  local vibrant_green = normalize_chip_bg(color("Constant", "fg", 0x7eca9c), normal_fg)
  local teal = normalize_chip_bg(color("PreProc", "fg", 0x519aba), normal_fg)

  local highlights = {
    NoCheatSheetAsciiHeader = { fg = blue, bg = section_bg, bold = true },
    NoCheatSheetSection = { fg = normal_fg, bg = section_bg },
    NoCheatSheetHeading = { fg = chip_fg, bg = blue, bold = true },
  }

  if config.options.theme == "grid" then
    highlights.NoCheatSheetAsciiHeader = { fg = blue, bold = true }

    local colors = {
      blue = blue,
      red = red,
      green = green,
      yellow = yellow,
      orange = orange,
      baby_pink = baby_pink,
      purple = purple,
      white = white,
      cyan = cyan,
      vibrant_green = vibrant_green,
      teal = teal,
    }

    for name, bg in pairs(colors) do
      highlights["NoCheatSheetHead" .. name] = { fg = chip_fg, bg = bg, bold = true }
    end

    return highlights
  end

  return highlights
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
