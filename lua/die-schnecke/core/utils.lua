local plenary = require('plenary.scandir')
local config = require('die-schnecke.core.config')
local api = vim.api

_G.P = function(val)
  print(vim.inspect(val))
  return val
end

local M = {}

M.get_visual_selection = function()
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- exit visual mode
    api.nvim_feedkeys(
      api.nvim_replace_termcodes("<Esc>",
        true, false, true), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then csrow, cerow = cerow, csrow end
  if cecol < cscol then cscol, cecol = cecol, cscol end
  local lines = vim.fn.getline(csrow, cerow)

  local tbl_length = function(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

  local n = tbl_length(lines)

  if n <= 0 then return "" end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)

  local str_result = table.concat(lines, "\n")
  local filetype = vim.bo.filetype
  return lines, filetype, str_result
end

M.get_code_before_cursor = function()
  local current_line = vim.fn.getline(".")
  local cursor_col = vim.fn.col(".")
  local filetype = vim.bo.filetype
  local code_before_cursor = current_line:sub(1, cursor_col)
  return code_before_cursor, filetype
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


--- get config by key
---@param key string
---@return table | any
---@usage M.get_config("foo") -> table | any
M.get_config = function(key)
  return config[key] or config.load()[key]
end

M.encode_to_json = function(data)
  local json = vim.fn.json_encode(data)
  json = vim.fn.shellescape(json)
  return json
end

M.write_to_buffer = function(lines)
  local bufnr = require("die-schnecke.core.ollama").result_bufnr

  if bufnr == nil or not api.nvim_buf_is_valid(bufnr) then
    error("No buffer found")
    return
  end

  local all_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local last_row = #all_lines
  local last_row_content = all_lines[last_row]
  local last_col = string.len(last_row_content)

  local text = table.concat(lines or {}, "\n")

  api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  api.nvim_buf_set_text(bufnr, last_row - 1, last_col,
    last_row - 1, last_col, vim.split(text, "\n"))

  -- Move the cursor to the end of the new lines
  api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

M.throw_to_left = function(bufnr)
  vim.cmd("vsplit")
  vim.cmd("vertical resize " .. 38)

  -- Move the new split to the far left
  vim.cmd("wincmd H")

  -- If a buffer ID is provided, open that buffer in the new window
  if bufnr then
    api.nvim_win_set_buf(0, bufnr)
  end
  return api.nvim_get_current_win()
end


M.switch = function(param, t)
  local case = t[param]
  if case then
    return case()
  end
  local defaultFn = t["default"]
  return defaultFn and defaultFn() or nil
end

return M
