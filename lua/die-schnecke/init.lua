local core = require('die-schnecke.core')
local config = require('die-schnecke.core.config')

local M = {}
M.init = function(opts)
  config.load(opts)
end

M.open = core.open
M.serve = core.serve

return M
