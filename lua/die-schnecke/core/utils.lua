local plenary = require('plenary.scandir')
local config = require('die-schnecke.core.config')

P = function(val)
  print(vim.inspect(val))
  return val
end

function R(name)
  package[name] = nil
  require "plenary.reload" (name)
  return require(name)
end

local M = {}

M.get_visual_selection = function()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

  if vim.tbl_isempty(lines) then
    return
  end

  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

M.get_file = function(path, mode)
  return io.open(path, mode)
end

M.fetch_dir_items = function(path)
  local entries = {}
  plenary.scan_dir(path, {
    add_dirs = true,
    hidden = false,
    depth = 2,
    on_insert = function(item, type)
      local entry = {
        title = vim.fn.fnamemodify(item, ':t'),
        type = type == 'directory' and 'dir' or 'file'
      }

      table.insert(entries, entry)
    end
  })

  return entries
end

M.get_config = function(key)
  return config[key] or config.load()[key]
end

M.encode_to_json = function(data)
  local json = vim.fn.json_encode(data)
  json = vim.fn.shellescape(json)
  return json
end

return M
