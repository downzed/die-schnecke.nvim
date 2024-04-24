local plenary = require('plenary.scandir')
local config = require('die-schnecke.core.config')

P = function(val)
  print(vim.inspect(val))
  return val
end

R = function(name)
  package[name] = nil
  return require(name)
end

local M = {}

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

return M



--[[
  local api = vim.api
  local M = { }

  M.init = function()
    M.setup_keymaps()
  end

  M.cleanup = function()
    M.buf = nil
    M.opts = nil
  end

  M.setup_keymaps = function()
    local mappings = config.get("mappings")
    for k, v in pairs(mappings) do
      api.nvim_set_keymap('n', k, ':lua require"die-schnecke".' .. v .. '<cr>', {
        nowait = true, noremap = true, silent = true
      })
    end
  end

  return M
--]]
