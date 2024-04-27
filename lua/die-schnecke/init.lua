-- Ensure the plugin is not loaded more than once
if _G.DieSchneckeLoaded ~= nil then
  return
end
_G.DieSchneckeLoaded = true

local core = require('die-schnecke.core.init')
local config = require('die-schnecke.core.config')
local notes = require('die-schnecke.core.notes')
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

  api.nvim_create_user_command('OpenDieSchnecke', core.open, { desc = desc })

  --[[
    TODO:
      1. trigger CursorMoved only if DieSchnecke is focused.
      2. onMove -> toggle preview popup on hovered item (get word under cursor)

    api.nvim_create_autocmd('CursorMoved', core.check)
    api.nvim_create_autocmd('CursorMoved', {
      -- pattern = { "*.c", "*.h" },
      callback = function(ev)
        print(string.format('event fired: s', vim.inspect(ev)))
      end
    })
  --]]

  -- Optional: Set up a keybinding to open the dashboard
  -- api.nvim_set_keymap('n', '<leader>XX', ':DieSchneckeToggle<CR>', { noremap = true, silent = true, desc = desc })
end

M.open = core.open
M.chat = ai.chat

return M
