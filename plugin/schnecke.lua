if vim.g.DieSchneckeLoaded ~= nil then
  return
end
vim.g.DieSchneckeLoaded = true

-- loading user auto-commands
require('die-schnecke.core.autocmd')
