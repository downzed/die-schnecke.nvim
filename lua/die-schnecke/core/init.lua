local n = require("nui-components")
local utils = require("die-schnecke.core.utils")

local M = {
  data = {},
  renderer = {},
  content = nil,
  is_open = false,
  -- win_id = nil
}

local coreState = n.create_signal({
  win_id = nil
})

M.set_notes_dir = function()
  local notes_dir = vim.fn.expand(utils.get_config("path"))
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, 'p')
  end
end

M.load_notes = function()
  local notes_dir = vim.fn.expand(utils.get_config("path"))
  local items = utils.fetch_dir_items(notes_dir)

  for _, item in ipairs(items) do
    if item.type == "file" then
      table.insert(M.data, item.title)
    end
  end
end


M.setupRenderer = function()
  local ren = n.create_renderer({
    width = 60,
    height = 10,
    on_mount = function()
      P("Mounted")
      M.is_open = true
      coreState.win_id = vim.api.nvim_get_current_win()
    end,
    on_unmount = function()
      P("Unmounted")
      M.is_open = false
    end
  })

  M.renderer = ren
end

M.setupContent = function()
  local notes = M.data
  local items = {}

  for _, noteTitle in ipairs(notes) do
    table.insert(items, n.option(noteTitle, { id = noteTitle })) -- Use the note title as the ID
  end


  local signal = n.create_signal({
    selected = items[1].id or {},
  })

  local select_list = n.select({
    border_label = "Quick Notes",
    autofocus = true,
    selected = signal.selected,
    data = items,

    on_select = function(node)
      print(node.id)
      signal.selected = node.id
    end,

    prepare_node = function(is_selected, node)
      -- print("Node: " .. node.id)
      -- print("Is selected: " .. tostring(is_selected))
      if is_selected then
        return node.id .. " ✓"
      end

      return node.id
    end,
  })

  M.content = function()
    return select_list
  end
end

M.initialize = function()
  M.setupRenderer()
  M.setupContent()
end

M.open = function()
  if M.is_open then
    return
  end

  M.initialize()
  M.renderer:render(M.content)
end

return M
