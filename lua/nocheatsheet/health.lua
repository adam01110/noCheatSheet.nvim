local M = {}

local health = vim.health or require "health"
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error

local function has_command(name)
  return vim.fn.exists(":" .. name) == 2
end

local function module_loads(name)
  local loaded, result = pcall(require, name)
  if loaded then
    ok(name .. " loads")
  else
    error(name .. " failed to load", { result })
  end

  return loaded, result
end

M.check = function()
  start "nocheatsheet"

  local loaded, plugin = module_loads "nocheatsheet"
  module_loads "nocheatsheet.config"
  module_loads "nocheatsheet.cheatsheet"
  module_loads "nocheatsheet.cheatsheet.grid"
  module_loads "nocheatsheet.cheatsheet.simple"

  if not loaded then
    return
  end

  if type(plugin.setup) == "function" then
    ok "setup() is available"
  else
    error "setup() is missing"
  end

  local config = require "nocheatsheet.config"

  if vim.tbl_contains({ "grid", "simple" }, config.options.theme) then
    ok("theme is valid: " .. config.options.theme)
  else
    error("theme is invalid: " .. vim.inspect(config.options.theme), { "Use 'grid' or 'simple'." })
  end

  if has_command(config.options.command) then
    ok("command is registered: :" .. config.options.command)
  else
    warn("command is not registered: :" .. config.options.command, { "Call require('nocheatsheet').setup()." })
  end

  local section = vim.api.nvim_get_hl(0, { name = "NoCheatSheetSection", link = false })

  if section.bg then
    ok "NoCheatSheetSection has a background"
  else
    warn(
      "NoCheatSheetSection has no background",
      { "Call setup() after your colorscheme or check highlight overrides." }
    )
  end

  local head = vim.api.nvim_get_hl(0, { name = "NoCheatSheetHeadblue", link = false })

  if config.options.theme ~= "grid" or head.bg then
    ok "grid header highlights have backgrounds"
  else
    warn(
      "NoCheatSheetHeadblue has no background",
      { "Call setup() after your colorscheme or check highlight overrides." }
    )
  end
end

return M
