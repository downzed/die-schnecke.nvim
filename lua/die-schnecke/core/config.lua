local M = {}

M.defaults = {
  header = "Welcome to Die Schnecke!",
  mappings = {
    ['<leader>xq'] = 'close()',
    ['<leader>xx'] = 'open()',
  },
  path = '~/die-schnecke.notes',
  max_items = 10,
}

M.load = function(user_config)
  user_config = user_config or {}
  local config = vim.tbl_deep_extend("force", {}, M.defaults, user_config)
  M.config = config
  return config
end

return M
