local n = require("nui-components")
local Line = require("nui.line")
local Text = require("nui.text")
-- local spinner_formats = require("nui-components.utils.spinner-formats")

local api = vim.api

local ollama = require("die-schnecke.core.ollama")
local utils = require("die-schnecke.core.utils")

local M = {
  renderer = {},
  is_open = false,
  is_chat = true,
  signal = {},
  buffer_id = "chat",
  filetype = "markdown"
}

local model_name = utils.get_config("llama").model

local default_signal = {
  user_msg = "",
  is_loading = false,
  buffer_label = M.is_chat and model_name or M.filetype,
  selected_prompt = "chat",
  select_size = 4,
  preview_content = "",
  is_code = false,
  is_preview_visible = false,
}

local reset = function()
  M = {
    buffer_id = "chat",
    renderer = {},
    is_open = false,
    is_chat = true,
    signal = {},
    filetype = "markdown"
  }
end

local create_renderer = function()
  local renderer = n.create_renderer({ width = 80, height = 8 })

  renderer:on_mount(function() M.is_open = true end)

  renderer:on_unmount(reset)

  return renderer
end

local options_list = {
  n.option("Chat with " .. model_name, { id = "chat" }),
  n.separator("Create"),
  n.option("JSDoc", { id = "to_jsdoc" }),
  n.option("README", { id = "to_readme" }),
  n.separator("Format"),
  n.option("Make this in TS", { id = "to_ts" }),
  n.option("Make this in JS", { id = "to_js" }),
}

local create_signal = function()
  return n.create_signal(default_signal)
end

local create_ui = function(renderer, bufnr, signal)
  local is_chat = signal.selected_prompt:map(function(option) return not (option == "chat") end)
  local is_preview_visible = signal.is_preview_visible:map(function(val) return not val end)

  local body = n.rows(
    n.text_input({
      id = "text_input",
      border_label = {
        icon = "",
        text = "You, Sir",
        align = "center"
      },
      autofocus = true,
      -- autoresize = false,
      wrap = true,
      max_lines = 1,
      padding = { top = 0, right = 1, bottom = 0, left = 1 },
      on_change = function(value)
        signal.msg = value
      end,

      hidden = is_chat
    }),
    --       n.gap({ size = 2 }),
    --       n.spinner({
    --         padding = {
    --           top = 1,
    --         },
    --         is_loading = signal.is_loading:negate(),
    --         frames = spinner_formats.dots_6,
    --       })
    --     )
    --   ),

    --   n.gap({ size = 1, hidden = signal.is_code }),

    n.select({
      id = "select",
      autofocus = not is_chat,
      size = signal.select_size,
      border_label = {
        align = "center",
        icon = "",
        text = "Prompts"
      },

      selected = signal.selected_prompt,

      on_blur = function()
        -- if is_preview_visible then
        -- signal.select_size = 2
        -- else
        signal.select_size = 4
        -- end
      end,

      on_focus = function()
        signal.select_size = 8
      end,

      data = options_list,

      on_select = function(node)
        signal.selected_prompt = node.id
        if node.id == "chat" then
          local input = renderer:get_component_by_id("text_input")
          input:focus()
        end
      end,

      prepare_node = function(is_selected, node)
        local line = Line()

        if is_selected then
          line:append(" " .. node.text .. " ")
        else
          -- local is_separator = node._type == "separator"
          if node._type == "separator" then
            line:append(node.text)
          else
            line:append(" " .. node.text)
          end
        end

        return line
      end,
    }),
    -- n.paragraph({
    --   lines = signal.context,
    --   is_focusable = false,
    --   hidden = signal.is_chat_open:negate(),
    --   border_style = "rounded",
    --   border_label = {
    --     icon = "",
    --     text = "Context"
    --   },
    --   max_lines = 2
    -- }),

    -- n.paragraph({
    --   id = "preview",
    --   autofocus = true,
    --   lines = signal.preview_content,
    --   flex = 2,
    --   border_label = {
    --     text = Text("Preview", "NuiComponentsBorderLabel"),
    --     icon = is_chat_visible and "󰭹" or "",
    --     align = "center",
    --   },
    --   border_style = "rounded",
    --   hidden = is_preview_visible
    -- })
    n.buffer({
      id = "ollama",
      autofocus = true,
      -- id = buffer_id,
      flex = 1,
      buf = bufnr,
      autoscroll = true,
      border_label = {
        text = Text("Preview", "NuiComponentsBorderLabel"),
        icon = is_chat and "󰭹" or "",
        align = "center",
      },
      border_style = "rounded",
      hidden = is_preview_visible,
      padding = { left = 1, right = 1 },
    })
  )

  return body
end

local runner = function(state, bufnr, winid)
  if not bufnr then
    return
  end

  print("󰜎 up")
  -- P(state)

  ollama.prompt_winid = winid

  api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')    -- Wipe buffer when hidden
  api.nvim_buf_set_option(bufnr, 'swapfile', false)      -- Disable swapfile for this buffer
  -- api.nvim_buf_set_option(bufnr, 'modifiable', not M.is_chat)
  api.nvim_buf_set_option(bufnr, 'filetype', M.filetype) -- make this buffer markdown

  -- TODO: msg should be the correct context when running with code

  -- if M.is_chat then
  ollama.exec(string.gsub(state.msg, "\n", ""))
  -- ollama.exec(M.signal:get_value().msg)
  -- else
  --   local val = M.signal:get_value().selected_prompt
  --   P(val)
  --   -- print("Running -> " .. M.signal:get_value().selected_prompt.text)
  -- end
end

local add_renderer_events = function(renderer, signal)
  renderer:add_mappings({
    {
      mode = { "n", "i" },
      key = { "<c-c>", "q" },
      handler = function()
        renderer:close()
      end,
    },
    {
      mode = "n",
      key = { "<c-r>", "<D-CR>" },
      handler = function()
        local state = signal:get_value()
        signal.is_preview_visible = true

        renderer:set_size({ height = 20 })

        local ollama_root = renderer:get_component_by_id("ollama")
        local bufnr = ollama_root.bufnr
        local winid = ollama_root.winid
        renderer:schedule(function() runner(state, bufnr, winid) end)
      end
    }
    -- {
    --   mode = "n",
    --   key = "<leader>p",
    --   handler = function()
    --     print("AM I HERE>")
    --     -- M.renderer:schedule(function()
    --     print("running")
    --     runner(bufnr)
    --     -- end)
    --   end
    -- },
    -- {
    --   mode = "i",
    --   key = "<c-r>",
    --   handler = function()
    --     if not M.signal.get_value().msg then
    --       return
    --     end

    --     renderer:set_size({ height = 30 })
    --     -- end

    --     if M.is_chat then
    --       M.signal.is_chat_open = true
    --     end

    --     M.renderer:schedule(function() runner(bufnr) end)
    --   end,
    -- },
  })
end

local create_window = function()
  local bufnr = api.nvim_create_buf(false, true)
  ollama.result_bufnr = bufnr

  M.renderer = create_renderer()
  local signal = create_signal()
  M.signal = signal

  local ui = create_ui(M.renderer, bufnr, signal)
  add_renderer_events(M.renderer, signal)

  M.renderer:render(function() return ui end)
end

M.init = function()
  ollama.run_llama_server()
end

M.open = function()
  if M.is_open then
    return M.renderer:focus()
  end
  create_window()

  -- if not with_selection then
  --   create_window()
  -- else
  --   -- TODO: code completion
  --   -- local code, ft = utils.get_code_before_cursor()
  --   -- print("Code before: " .. code)
  --   -- print("filetype: " .. ft)

  --   -- TODO: code review
  --   local visual_lines = utils.get_visual_selection() or {}

  --   M.is_chat = false
  --   M.filetype = vim.bo.filetype


  --   -- FIXME: this is ugly
  --   vim.defer_fn(function()
  --     -- vim.cmd("set number")
  --     api.nvim_buf_set_option(ollama.result_bufnr, "filetype", M.filetype)
  --   end, 0)

  --   utils.write_to_buffer(visual_lines)

  -- api.nvim_buf_set_option(ollama.result_bufnr, 'modifiable', true)
  -- end
end

return M
