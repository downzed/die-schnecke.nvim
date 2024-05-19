-- Ensure the plugin is not loaded more than once
if _G.DieSchneckeLoaded ~= nil then
  return
end
_G.DieSchneckeLoaded = true

local core = require('die-schnecke.core.init')
local config = require('die-schnecke.core.config')

local api = vim.api
local M = {}

M.setup = function(opts)
  config.load(opts)
  core.init()

  local desc = 'Toggle Die Schnecke!'

  api.nvim_create_user_command('OpenDieSchnecke', function() core.open() end, { desc = desc })
  api.nvim_create_user_command('OpenDieSchneckeWithSelectedCode', function() core.chat_with_code() end,
    { desc = desc .. " with Code" })
end

M.open = core.open

return M
