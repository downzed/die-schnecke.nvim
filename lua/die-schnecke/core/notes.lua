local utils = require("die-schnecke.core.utils")
local M = { data = {} }

M.load = function()
  local notes_dir = vim.fn.expand(utils.get_config("path"))
  local items = utils.fetch_dir_items(notes_dir)

  for _, item in ipairs(items) do
    if item.type == "file" then
      table.insert(M.data, item.title)
    end
  end
end

M.get = function()
  return M.data
end

return M
