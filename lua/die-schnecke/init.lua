-- Ensure the plugin is not loaded more than once
if _G.DieSchneckeLoaded ~= nil then
  return
end
_G.DieSchneckeLoaded = true

local core = require('die-schnecke.core.init')
local config = require('die-schnecke.core.config')
-- local notes = require('die-schnecke.core.notes')
local ai = require('die-schnecke.core.ai')

local api = vim.api
local M = {}

M.setup = function(opts)
  config.load(opts)
  -- config.set_notes_dir()
  -- notes.load()
  -- core.load_notes()
  core.initialize()

  local desc = 'Toggle Die Schnecke!'

  api.nvim_create_user_command('OpenDieSchnecke', M.open, { desc = desc })
end

M.open = core.open
M.open_with_selection = function() core.open(true) end

return M
