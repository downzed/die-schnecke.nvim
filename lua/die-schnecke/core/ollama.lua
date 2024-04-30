local _api = vim.api
local utils = require("die-schnecke.core.utils")
local write_to_buffer = utils.write_to_buffer

local M = {
  result_bufnr = nil,
  prompt_winid = nil,
}

local get_is_model_exist = function(model)
  for _, m in ipairs(M.models) do
    if m == model then
      return true
    end
  end
  return false
end

M.run_llama_server = function()
  local port = utils.get_config("llama").port
  local ok = pcall(io.popen, "ollama serve > /dev/null 2>&1 &")

  if not ok then
    print("Failed to start ollama")
    return
  end

  local response = vim.fn.systemlist("curl --silent --no-buffer http://localhost:" .. port .. "/api/tags")

  if not response or vim.tbl_isempty(response) then
    print("ollama not running or no response received.. 😢")
    return
  end

  local model_list = vim.fn.json_decode(response)

  if not model_list then
    print(" Pulling llama3 for you ")
    pcall(io.popen, "ollama pull llama3 > /dev/null 2>&1 &")
    return
  end

  local models = {}
  for key, _ in pairs(model_list.models or {}) do
    local name = string.gsub(model_list.models[key].name, ":latest", "")
    table.insert(models, name)
  end

  M.models = models
end

local process_cmd_result = function(res)
  local job_id = M.job_id

  if string.len(res) == 0 or not job_id then return end

  local text
  local success, result = pcall(vim.fn.json_decode, res)

  if success then
    if result ~= nil then
      if result.message and result.message.content then
        local content = result.message.content
        text = content
        M.context = M.context or {}
        M.context_buffer = M.context_buffer or ""
        M.context_buffer = M.context_buffer .. content
        if result.done then
          table.insert(M.context, {
            role = 'assistant',
            content = M.context_buffer
          })
          -- Clear the buffer as we're done with this sequence of messages
          M.context_buffer = ""
          write_to_buffer({ "\n", "󰐁", "\n" })
        end
      end
    end
  else
    write_to_buffer({ "", "====== ERROR ====", res, "-------------", "" })
    vim.fn.jobstop(job_id)
  end

  if text == nil then return end

  local lines = vim.split(text, "\n")
  write_to_buffer(lines)
end

local run_cmd = function(cmd)
  if M.result_bufnr == nil and
      not _api.nvim_win_is_valid(M.prompt_winid) then
    return
  end

  local signal = require "die-schnecke.core.init".signal

  signal.is_loading = true

  local on_exit = function(_, exit_code, _)
    if exit_code ~= 0 then
      print("Command failed with exit code " .. exit_code)
    end
  end

  local partial_data = ""

  local on_stdout = function(_, data, event)
    if event == "stderr" or not data then
      signal.is_loading = false
      return
    end

    for _, line in ipairs(data) do
      partial_data = partial_data .. line
      if line:sub(-1) == "}" then
        partial_data = partial_data .. "\n"
      end
    end

    local lines = vim.split(partial_data, "\n", { trimempty = true })
    partial_data = table.remove(lines) or ""

    for _, line in ipairs(lines) do
      process_cmd_result(line)
    end

    if partial_data:sub(-1) == "}" then
      process_cmd_result(partial_data)
      partial_data = ""
    end
  end

  M.job_id =
      vim.fn.jobstart(cmd, {
        stdout_buffered = false,
        stderr_buffered = true,
        on_stdout = on_stdout,
        on_stderr = on_stdout,
        on_exit = on_exit
      })
end

M.exec = function(message)
  local llama_config = utils.get_config('llama')
  local is_model_exist = get_is_model_exist(llama_config.model)

  if not is_model_exist then
    write_to_buffer({ "󱙑 Model not found: " .. llama_config.model })
    return
  end

  local messages = {
    {
      role = "user",
      content = message
    }
  }

  local _local_data = { -- TODO: hould be expended when using context
    messages = messages
  }

  local data = vim.tbl_deep_extend("force", {}, _local_data, llama_config)

  local json_body = utils.encode_to_json(data)
  local port = utils.get_config('llama').port
  local cmd = string.format(
    "curl --silent --no-buffer http://localhost:" .. port .. "/api/chat -d %s",
    json_body
  )

  run_cmd(cmd)
end


return M
