local M = {}

M.defaults = {
  header = "Welcome to Die Schnecke!",
  mappings = {
    ['<leader>xq'] = 'close()',
    ['<leader>xx'] = 'open()',
  },
  path = '~/die-schnecke.notes',
  max_items = 10,
  llama = {
    model = "Ziggi",
    -- stream = false,
    port  = "11434"
  }
}

M.load = function(user_config)
  user_config = user_config or {}
  local config = vim.tbl_deep_extend("force", {}, M.defaults, user_config)
  M.config = config
  return config
end

M.set_notes_dir = function()
  local notes_dir = vim.fn.expand(M.load()["path"])
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, 'p')
  end
end

return M
