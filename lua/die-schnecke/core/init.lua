local n = require("nui-components")
local Line = require("nui.line")
local Text = require("nui.text")

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
  n.separator("Completion"),
  n.option("From comment", { id = "cmp_comment" }),
  n.option("Finish the function", { id = "cmp_infill" }),
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

local set_code_preview = function()
  M.signal.is_ollama_visible = false
  local register = vim.fn.getreg('"')

  -- Split the content into lines
  local lines = {}
  for line in register:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end

  M.renderer:set_size({ height = 20 })

  M.signal.is_preview_visible = true
  M.signal.preview_content = string.gsub(register, "\n", "")

  local code_preview = M.renderer:get_component_by_id("code_preview")

  local code_preview_bufnr = code_preview.bufnr

  vim.api.nvim_buf_set_lines(code_preview_bufnr, 0, -1, false, lines)
end

local create_ui = function(renderer, signal)
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
          set_code_preview()
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

    n.buffer({
      id = "code_preview",
      autofocus = true,
      filetype = M.filetype,
      flex = 1,
      border_label = {
        text = Text("Code Preview (" .. M.filetype .. ")", "NuiComponentsBorderLabel"),
        icon = "󰘦",
        align = "center",
      },
      buf = api.nvim_create_buf(false, true),
      border_style = "rounded",
      hidden = is_preview_hidden
    }),

    n.buffer({
      id = "ollama_preview",
      autofocus = true,
      -- id = buffer_id,
      flex = 1,
      buf = api.nvim_create_buf(false, true),
      autoscroll = true,
      border_label = {
        text = Text("Ollama", "NuiComponentsBorderLabel"),
        icon = "󱜿",
        align = "center",
      },
      border_style = "rounded",
      hidden = is_ollama_hidden,
      padding = { left = 1, right = 1 },
    })
  )

  return body
end

local runner = function(state, bufnr, winid, is_chat)
  if not bufnr then
    vim.notify("why DaFaque??", vim.log.levels.ERROR)
    return
  end

  print("󰜎 up")
  print(M.filetype)
  ollama.result_bufnr = bufnr
  ollama.prompt_winid = winid

  api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')    -- Wipe buffer when hidden
  api.nvim_buf_set_option(bufnr, 'swapfile', false)      -- Disable swapfile for this buffer
  api.nvim_buf_set_option(bufnr, 'filetype', M.filetype) -- make this buffer markdown

  local prompt = utils.switch(state.selected_prompt, {
    ["chat"] = function()
      return {
        text = string.gsub(state.msg, "\n", ""),
        filetype = 'markdown'
      }
    end,

    ["refactor_improve"] = function()
      return {
        text = "Improve the following code, only output the result in format:\n```"
            .. M.filetype
            .. "\n"
            .. state.preview_content
            .. "\n```",
        filetype = M.filetype
      }
    end,

    ["refactor_convert_to_ts"] = function()
      return {
        text = "Convert the following javascript code to TypeScript, only output the result in typeScript format.\n"
            .. "Answer only in code!, no markdown template, only typescript code, please.\n"
            .. state.preview_content
            .. "\n",
        filetype = "typescript"
      }
    end,

    ["cmp_comment"] = function()
      return {
        text = state.preview_content,
        filetype = M.filetype
      }
    end,

    ["cmp_infill"] = function()
      return {
        text = "<PRE>" .. state.preview_content .. "\n<SUF><MID>",
        filetype = M.filetype
      }
    end

  })

  if prompt == nil then return end

  ollama.set_context({ prompt.text })

  if is_chat then
    ollama.exec()
  else
    M.renderer:focus()
    api.nvim_buf_set_option(bufnr, 'filetype', 'markdown') -- make this buffer markdown
    ollama.exec()
  end
end

local add_renderer_events = function(renderer, signal)
  renderer:add_mappings({
    {
      mode = { "n", "i" },
      key = { "<c-c>" },
      handler = function()
        renderer:close()
      end,
    },
    {
      mode = "n",
      key = { "<c-r>", "<D-CR>" },
      handler = function()
        local state = signal:get_value()
        local is_chat = true
        local bufnr
        local winid

        if state.selected_prompt == "chat" then
          signal.is_ollama_visible = true
          signal.is_preview_visible = false

          renderer:set_size({ height = 20 })

          local ollama_preview = renderer:get_component_by_id("ollama_preview")

          bufnr = ollama_preview.bufnr
          winid = ollama_preview.winid
          renderer:schedule(function()
            runner(state, bufnr, winid, is_chat)
          end)
        else
          -- FIXME: if win/buf already exists, use that and focus that
          is_chat = false
          bufnr = api.nvim_create_buf(false, true)
          winid = utils.throw_to_left(bufnr)
          runner(state, bufnr, winid, is_chat)
        end
      end
    }
  })
end

local create_window = function(default_prompt)
  M.renderer = create_renderer()
  local signal = create_signal(default_prompt)

  M.signal = signal

  local ui = create_ui(M.renderer, signal)

  add_renderer_events(M.renderer, signal)

  M.renderer:render(function() return ui end)
end

M.init = function()
  ollama.run_llama_server()
end

M.chat_with_code = function()
  if M.is_open then
    M.renderer:focus()
  end

  M.filetype = vim.bo.filetype
  create_window("refactor_improve")
  set_code_preview()
end

M.open = function()
  if M.is_open then
    return M.renderer:focus()
  end

  create_window("chat")
end

return M
