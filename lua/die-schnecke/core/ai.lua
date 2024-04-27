local M = {
  current_response = nil,
}

M.load_llama = function()
  pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
  print("ollama started 🚀")
  local res = vim.fn.systemlist("curl --silent --no-buffer http://localhost:11434/api/tags")
  local list = vim.fn.json_decode(res)

  if not list then
    print("Error: no models exist.\nPull a model first!")
    -- pcall(io.popen, "ollama pull llama3 > /dev/null 2>&1 &")
    return
  end

  local models = {}
  for key, _ in pairs(list.models or {}) do
    table.insert(models, list.models[key].name)
  end

  M.models = models
end

local get_json = function(data)
  local json = vim.fn.json_encode(data)
  json = vim.fn.shellescape(json)
  -- if vim.o.shell == 'cmd.exe' then
  --   json = string.gsub(json, '\\\"\"', '\\\\\\\"')
  -- end
  return json
end

M.chat = function(message)
  local data = {
    stream = false,
    model = "llama3",
    messages = {
      {
        role = "user",
        content = message
      }
    }
  }

  local json_body = get_json(data)
  local curl_cmd = string.format("curl --silent --no-buffer http://localhost:11434/api/chat -d " .. json_body)
  local response = vim.fn.system(curl_cmd)
  local parsed_response = vim.fn.json_decode(response) or {}

  local current_response = parsed_response.message.content

  return vim.split(current_response, "\n")
end

return M
