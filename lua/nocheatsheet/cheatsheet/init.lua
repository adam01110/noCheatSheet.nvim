local M = {}
local api = vim.api
local config = require "nocheatsheet.config"

local function capitalize(str)
  return (str:gsub("^%l", string.upper))
end

M.get_mappings = function(mappings, tb_to_add)
  local excluded_groups = config.options.excluded_groups

  for _, v in ipairs(mappings) do
    local desc = v.desc

    -- dont include mappings which have \n in their desc
    if not desc or (select(2, desc:gsub("%S+", "")) <= 1) or string.find(desc, "\n") then
      goto continue
    end

    local heading = desc:match "%S+" -- get first word
    heading = (v.mode ~= "n" and heading .. " (" .. v.mode .. ")") or heading

    -- useful for removing groups || <Plug> lhs keymaps from cheatsheet
    if
      vim.tbl_contains(excluded_groups, heading)
      or vim.tbl_contains(excluded_groups, desc:match "%S+")
      or string.find(v.lhs, "<Plug>")
    then
      goto continue
    end

    heading = capitalize(heading)

    if not tb_to_add[heading] then
      tb_to_add[heading] = {}
    end

    local keybind = string.sub(v.lhs, 1, 1) == " " and "<leader> +" .. v.lhs or v.lhs

    desc = v.desc:match "%s(.+)" -- remove first word from desc
    desc = capitalize(desc)

    table.insert(tb_to_add[heading], { desc, keybind })

    ::continue::
  end
end

M.organize_mappings = function()
  local tb_to_add = {}
  local modes = { "n", "i", "v", "t" }

  for _, mode in ipairs(modes) do
    local keymaps = vim.api.nvim_get_keymap(mode)
    require("nocheatsheet.cheatsheet").get_mappings(keymaps, tb_to_add)

    local bufkeymaps = vim.api.nvim_buf_get_keymap(0, mode)
    require("nocheatsheet.cheatsheet").get_mappings(bufkeymaps, tb_to_add)
  end

  return tb_to_add

  -- remove groups which have only 1 mapping
  -- for key, x in pairs(tb_to_add) do
  --   if #x <= 1 then
  --     tb_to_add[key] = nil
  --   end
  -- end
end

M.autocmds = function(buf)
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "nocheatsheet"
  vim.wo.number = false
  vim.wo.list = false
  vim.wo.wrap = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.colorcolumn = "0"
  vim.wo.foldcolumn = "0"
  vim.g.nocheatsheet_displayed = true

  local group_id = api.nvim_create_augroup("NoCheatSheet", { clear = true })

  api.nvim_create_autocmd("BufWinLeave", {
    group = group_id,
    buffer = buf,
    callback = function()
      vim.g.nocheatsheet_displayed = false
      pcall(api.nvim_del_augroup_by_name, "NoCheatSheet")
    end,
  })

  api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group_id,
    callback = function()
      require("nocheatsheet.cheatsheet." .. config.options.theme)(
        vim.g.nocheatsheet_buf,
        vim.g.nocheatsheet_win,
        "redraw"
      )
    end,
  })

  local close_buf = function()
    api.nvim_buf_delete(buf, { force = true })
  end

  vim.keymap.set("n", "q", close_buf, { buffer = buf })
  vim.keymap.set("n", "<ESC>", close_buf, { buffer = buf })

  vim.g.nocheatsheet_buf = buf
  vim.g.nocheatsheet_win = vim.fn.bufwinid(buf)
end

M.rand_hlgroup = function()
  local hlgroups =
    { "blue", "red", "green", "yellow", "orange", "baby_pink", "purple", "white", "cyan", "vibrant_green", "teal" }

  return "NoCheatSheetHead" .. hlgroups[math.random(1, #hlgroups)]
end

M.state = {
  mappings_tb = {},
}

return M
