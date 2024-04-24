local n = require("nui-components")
local spinner_formats = require("nui-components.utils.spinner-formats")
local notes = require("die-schnecke.core.notes").get()

local M = {
  data = {},
  renderer = {},
  content = nil,
  is_open = false,
  -- win_id = nil
}

M.setupRenderer = function()
  local renderer = n.create_renderer({
    width = 60,
    height = 4,
    -- position = 100
  })



  renderer:on_mount(function()
    M.is_open = true
    --   M.win_id = vim.api.nvim_get_current_win()
  end)

  renderer:on_unmount(function()
    M.is_open = false
    M.renderer = nil
  end)

  M.renderer = renderer
end

M.setupContent = function()
  local items = {}

  for _, noteTitle in ipairs(notes) do
    table.insert(items, n.option(noteTitle, { id = noteTitle })) -- Use the note title as the ID
  end


  -- local signal = n.create_signal({
  --   selected = items[1].id or {},
  -- })

  -- local select_list = n.select({
  --   border_label = "Quick Notes",
  --   autofocus = true,
  --   selected = signal.selected,
  --   data = items,

  --   on_select = function(node)
  --     print(node.id)
  --     signal.selected = node.id
  --   end,

  --   prepare_node = function(is_selected, node)
  --     -- print("Node: " .. node.id)
  --     -- print("Is selected: " .. tostring(is_selected))
  --     if is_selected then
  --       return node.id .. " ✓"
  --     end

  --     return node.id
  --   end,
  -- })
  local signal = n.create_signal({
    is_loading = false,
    text = "nui.components",
  })

  local body = function()
    return n.rows(
      n.columns(
        { flex = 0 },
        n.text_input({
          id = "text-input",
          autofocus = true,
          flex = 1,
          max_lines = 1,
        }),
        n.gap(1),
        n.button({
          label = "Send",
          hidden = signal.is_loading,
          padding = {
            top = 1,
          },
          on_press = function()
            signal.is_loading = true
            vim.defer_fn(function()
              local ref = M.renderer:get_component_by_id("text-input")
              signal.is_loading = false
              signal.text = ref:get_current_value()
            end, 2000)
          end,
        }),
        n.spinner({
          is_loading = signal.is_loading,
          frames = spinner_formats.pipe,
          hidden = not signal.is_loading,
        })
      ),
      n.paragraph({
        lines = signal.text,
        align = "center",
        is_focusable = false,
      })
    )
  end

  M.content = body
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
