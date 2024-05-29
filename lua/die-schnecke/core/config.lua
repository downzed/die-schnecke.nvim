--- Default configuration settings.
-- @module M.defaults

--- Path to the notes file.
-- @field path
-- @string path The default file path where notes or data will be stored.
-- @default ~/die-schnecke.notes

--- Maximum number of items.
-- @field max_items
-- @int max_items -- The maximum number of items to handle or display.
-- @default 10

local M = {}
M.default_config = {
  path = '~/die-schnecke.notes',
  max_items = 10,
  llama = {
    model  = "compy",
    stream = true,
    port   = "11434"
  },
}

---@param user_config table | nil
---@return table config
M.load = function(user_config)
  user_config = user_config or {}
  local config = vim.tbl_deep_extend("force", {}, M.default_config, user_config)
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
