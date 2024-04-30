-- Ensure the plugin is not loaded more than once
if _G.DieSchneckeLoaded ~= nil then
  return
end
_G.DieSchneckeLoaded = true

local core = require('die-schnecke.core.init')
local config = require('die-schnecke.core.config')
-- local notes = require('die-schnecke.core.notes')

local api = vim.api
local M = {}

M.setup = function(opts)
  config.load(opts)
  -- config.set_notes_dir()
  -- notes.load()
  -- core.load_notes()
  core.init()

  local desc = 'Toggle Die Schnecke!'

  api.nvim_create_user_command('OpenDieSchnecke', function() core.open() end, { desc = desc })
  -- config.map("x", "<C-e>", '<cmd>lua require("die-schnecke").chat_with_code()<CR>',
  --   { noremap = true, silent = true })
end

M.open = core.open
-- M.code_completion = function()
--
-- TODO: implement
-- should suggest code completion based on current line,
-- but take into consideration the entire buffer/file as context.
--
-- end

-- M.chat_with_code = function() core.open(true) end

return M
