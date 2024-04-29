local n = require("nui-components")
local spinner_formats = require("nui-components.utils.spinner-formats")

local ai = require("die-schnecke.core.ai")
local utils = require("die-schnecke.core.utils")

local M = {
  -- data = {
  --   stream = false,
  --   model = "Bob",
  -- },
  renderer = {},
  content = nil,
  is_open = false,
  signal = {},
}

local is_ollama_running = function()
  local command = "ps aux | grep 'ollama serve' | grep -v grep"
  local handle = io.popen(command)

  if handle == nil then return end

  local result = handle:read("*a")
  handle:close()

  if result == "" then return false end
  return true
end

local model_name = utils.get_config("llama").model

M.create_window = function()
  local renderer = n.create_renderer({
    width = 60,
    height = 3,
  })

  local bufnr = vim.api.nvim_create_buf(false, true)

  renderer:on_mount(function()
    M.is_open = true
  end)

  renderer:on_unmount(function()
    M.is_open = false
    M.renderer = nil
  end)


  local signal = n.create_signal({
    chat = "",
    is_preview_visible = false,
    is_loading = false,
    model_name = model_name or ""
  })

  M.signal = signal

  local body = function()
    return n.box({ flex = 1, direction = "column" },
      n.rows(
        { size = 3 },
        n.columns(
          { flex = 2 },
          n.text_input({
            flex = 1,
            border_label = "Message",
            autofocus = true,
            wrap = true,
            max_lines = 4,
            on_change = function(value)
              signal.chat = value
            end,
          }),
          n.gap({ size = 2 }),
          n.spinner({
            padding = {
              top = 1,
            },
            is_loading = signal.is_loading:negate(),
            frames = spinner_formats.shark,
          })
        )
      ),
      n.buffer({
        id = "preview",
        flex = 1,
        buf = bufnr,
        autofocus = true,
        autoscroll = true,
        border_label = "# Chat with " .. (model_name or "llama"),
        hidden = signal.is_preview_visible:negate(),
        filetype = "markdown",
      })
    )
  end

  renderer:add_mappings({
    {
      mode = { "n" },
      key = "<CR>",
      handler = function()
        local state = signal:get_value()

        if not is_ollama_running() then
          return
        end

        renderer:set_size({ height = 20 })
        signal.is_preview_visible = true

        renderer:schedule(function()
          ai.result_bufnr = bufnr
          ai.prompt_winid = renderer:get_component_by_id("preview").winid

          vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')    -- Wipe buffer when hidden
          vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)      -- Disable swapfile for this buffer
          vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown') -- make this buffer markdown
          -- vim.cmd("setlocal rnu")

          ai.exec(state.chat)
        end)
      end,
    },
  })

  renderer:render(body)
  M.renderer = renderer
end

M.initialize = function()
  ai.run_llama_server()
end

M.open = function(with_selection)
  if M.is_open then
    return
  end

  if with_selection then
    local current_text = utils.get_visual_selection() or ""
    if current_text ~= "" then
      print("Current text: " .. current_text)
    end
    return
  end

  M.create_window()
end

return M
