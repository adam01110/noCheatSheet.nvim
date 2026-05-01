local M = {}

M.defaults = {
  command = "Cheatsheet",
  theme = "grid", -- "grid" or "simple"
  excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
  highlights = {},
}

M.options = vim.deepcopy(M.defaults)

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M
