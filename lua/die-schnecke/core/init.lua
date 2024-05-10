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
  is_ollama_visible = false,
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
  n.option("Chat", { id = "chat" }),
  n.separator("Refactor"),
  n.option("Suggest ways to improve code readability and efficiency", { id = "refactor_improve" }),
  n.option("Convert to TypeScript", { id = "refactor_convert_to_ts" }),
  n.separator("Create Docs"),
  n.option("LuaDoc", { id = "create_luadoc" }),
  n.option("JSDoc", { id = "create_jsdoc" }),
  n.option("README", { id = "create_readme" }),
}

local create_signal = function(default_prompt)
  local signal_config = vim.tbl_deep_extend("force", {}, default_signal, { selected_prompt = default_prompt })
  return n.create_signal(signal_config)
end

local create_ui = function(renderer, bufnr, signal)
  local is_chat_hidden = signal.selected_prompt:map(function(option) return not (option == "chat") end)
  local is_ollama_hidden = signal.is_ollama_visible:negate()
  local is_preview_hidden = signal.is_preview_visible:negate()

  local body = n.rows(
    n.text_input({
      id = "text_input",
      border_label = {
        icon = "",
        text = "Chat with " .. model_name,
        align = "center"
      },
      autofocus = false,
      -- autoresize = false,
      wrap = true,
      max_lines = 1,
      padding = { top = 0, right = 1, bottom = 0, left = 1 },
      on_change = function(value)
        signal.msg = value
      end,

      hidden = is_chat_hidden
    }),
    --       n.gap({ size = 2 }),
    -- n.spinner({
    --   size = 1,
    --   padding = {
    --     top = 1,
    --   },
    --   is_loading = signal.is_loading:negate(),
    --   -- frames = spinner_formats.dots_6,
    -- })

    --   n.gap({ size = 1, hidden = signal.is_code }),

    n.select({
      id = "select",
      size = signal.select_size,
      border_label = {
        align = "center",
        icon = "",
        text = "Prompts"
      },
      autofocus = true,
      selected = signal.selected_prompt,

      on_blur = function()
        -- if is_ollma_visible then
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
          signal.is_preview_visible = false
          renderer:set_size({ height = 8 })

          local input = renderer:get_component_by_id("text_input")

          input:focus()
        else
          renderer:set_size({ height = 20 })
          signal.is_preview_visible = true
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

    n.buffer({
      id = "code_preview",
      autofocus = true,
      -- lines = signal.preview_content,
      filetype = M.filetype,
      flex = 1,
      border_label = {
        text = Text("Code Preview", "NuiComponentsBorderLabel"),
        icon = "󰘦",
        align = "center",
      },
      buf = bufnr,
      border_style = "rounded",
      hidden = is_preview_hidden
    }),

    n.buffer({
      id = "ollama",
      autofocus = true,
      -- id = buffer_id,
      flex = 1,
      buf = bufnr,
      autoscroll = true,
      border_label = {
        text = Text("Ollama", "NuiComponentsBorderLabel"),
        icon = is_chat_hidden and "" or "󰭹",
        align = "center",
      },
      border_style = "rounded",
      hidden = is_ollama_hidden,
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

  ollama.result_bufnr = bufnr
  ollama.prompt_winid = winid

  if state.selected_prompt == "chat" and state.msg ~= "" then
    api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')    -- Wipe buffer when hidden
    api.nvim_buf_set_option(bufnr, 'swapfile', false)      -- Disable swapfile for this buffer
    -- -- api.nvim_buf_set_option(bufnr, 'modifiable', not M.is_chat)
    api.nvim_buf_set_option(bufnr, 'filetype', M.filetype) -- make this buffer markdown

    -- -- TODO: msg should be the correct context when running with code

    -- -- if M.is_chat then
    ollama.exec(string.gsub(state.msg, "\n", ""))
    -- ollama.exec(M.signal:get_value().msg)
  else
    P(state)
  end
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

        if state.selected_prompt == "chat" then
          signal.is_ollama_visible = true
          signal.is_preview_visible = false

          renderer:set_size({ height = 20 })

          local ollama_root = renderer:get_component_by_id("ollama")

          local bufnr = ollama_root.bufnr
          local winid = ollama_root.winid
          renderer:schedule(function() runner(state, bufnr, winid) end)
        else
          P(state)
          local bufnr = api.nvim_create_buf(true, false)
          ollama.result_bufnr = bufnr
          local winid = utils.throw_to_left()
          ollama.prompt_winid = winid
        end
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

local create_window = function(default_prompt)
  local bufnr = api.nvim_create_buf(false, true)

  M.renderer = create_renderer()
  local signal = create_signal(default_prompt)
  M.signal = signal

  local ui = create_ui(M.renderer, bufnr, signal)
  add_renderer_events(M.renderer, signal)

  M.renderer:render(function() return ui end)
end

M.init = function()
  ollama.run_llama_server()
end

M.chat_with_code = function()
  M.filetype = vim.bo.filetype
  local register = vim.fn.getreg('"')
  -- Split the content into lines
  local lines = {}
  for line in register:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end

  local default_prompt = "refactor_improve"
  M.signal.selected_prompt = default_prompt --"refactor_improve"

  create_window(default_prompt)
  M.renderer:set_size({ height = 20 })

  M.signal.is_preview_visible = true
  M.signal.preview_content = string.gsub(register, "\n", "")

  utils.write_to_buffer(lines)

  -- local preview_code = M.renderer:get_component_by_id("code_preview")
  -- previ

  -- local bufnr = preview_code.bufnr


  -- local visual_lines = utils.get_visual_selection() or {}
end

M.open = function()
  if M.is_open then
    return M.renderer:focus()
  end

  create_window()

  --   -- TODO: code completion
  --   -- local code, ft = utils.get_code_before_cursor()
  --   -- print("Code before: " .. code)
  --   -- print("filetype: " .. ft)
end

return M
