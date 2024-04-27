local n = require("nui-components")
local ai = require("die-schnecke.core.ai")

local M = {
  data = {},
  renderer = {},
  content = nil,
  is_open = false,
  -- win_id = nil
}

local is_ollama_running = function()
  local command = "ps aux | grep 'ollama serve' | grep -v grep"
  local handle = io.popen(command)

  if handle == nil then return end

  local result = handle:read("*a")
  handle:close()

  if result == "" then return false end -- "Ollama serve is not running."
  return true                           -- "Ollama serve is running."
end

M.setup_renderer = function()
  local renderer = n.create_renderer({
    width = 60,
    height = 3,
  })

  local bufnr = vim.api.nvim_create_buf(false, true)

  renderer:on_mount(function()
    M.is_open = true
    --   M.win_id = vim.api.nvim_get_current_win()
  end)

  renderer:on_unmount(function()
    M.is_open = false
    M.renderer = nil
  end)

  local signal = n.create_signal({
    chat = "",
    is_preview_visible = false,
  })

  local body = function()
    return n.rows(
      n.text_input({
        border_label = "Chat",
        autofocus = true,
        wrap = true,
        on_change = function(value)
          signal.chat = value
        end,
      }),
      n.buffer({
        id = "preview",
        flex = 1,
        buf = bufnr,
        autoscroll = true,
        border_label = "Preview",
        hidden = signal.is_preview_visible:negate(),
        filetype = 'markdown'
      })
    )
  end

  renderer:add_mappings({
    {
      mode = { "n" },
      key = "<CR>",
      handler = function()
        -- local gen = require("gen")
        local state = signal:get_value()

        renderer:set_size({ height = 20 })
        signal.is_preview_visible = true

        renderer:schedule(function()
          -- local win = renderer:get_component_by_id("preview").winid
          -- P(win)
          local data = ai.chat(state.chat)

          if not is_ollama_running() then
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "please run ollama serve" }) -- Insert data into the buffer
            return
          end
          if data == nil then return end

          -- You may want to set some buffer-specific options here
          -- vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile') -- Non-file buffer
          vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe') -- Wipe buffer when hidden
          vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)   -- Disable swapfile for this buffer

          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data)   -- Insert data into the buffer

          -- gen.float_win = renderer:get_component_by_id("preview").winid
          -- gen.result_buffer = buf
          -- gen.exec({ prompt = state.chat })
        end)
      end,
    },
  })

  renderer:render(body)
  M.renderer = renderer
end

M.initialize = function()
  ai.load_llama()
  M.setup_renderer()
end

M.open = function()
  if M.is_open then
    return
  end

  -- M.initialize()
  M.setup_renderer()
end

return M
