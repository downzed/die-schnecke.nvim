---@class die_schnecke_subcommand
---@field impl fun(args: string[], opts: table): nil
---@field done? fun(subcmd_arg: string): string[] (optional)

---@type table<string, die_schnecke_subcommand>
local subcommands = {
  serve = {
    -- TODO: impl = core.serve,
    impl = function() print("TODO: serve") end,
    done = function(subcmd_arg)
      vim.notify('serve .. ' .. subcmd_arg)
      return { 'serve', subcmd_arg }
    end
  },
  chat = {
    -- TODO: impl = core.chat,
    impl = function() print("TODO: chat") end
  },
  chat_with_code = {
    -- TODO: impl = core.chat_with_code,
    impl = function() print("TODO: chat_with_code") end,
  },
  -- init = {
  --   impl = function(_, opts)
  --     config.load(opts)
  --   end,
  -- }
}

---@param opts table :h lua-guide-commands-create
local function main_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommands[subcommand_key]
  if not subcommand then
    vim.notify("die-schnecke: Unknown command: " .. subcommand_key, vim.log.levels.WARN)
    return
  end
  -- Invoke the subcommand
  vim.notify("Invoked the subcommand: [" .. subcommand_key .. "]")
  subcommand.impl(args, opts)
end

vim.api.nvim_create_user_command('DieSchnecke', main_cmd, {
  nargs = "+",
  desc = "DieSchnecke command with subcommand completions",
  complete = function(arg_lead, cmdline, _)
    -- Get the subcommand.
    local subcmd_key, subcmd_arg_lead = cmdline:match("^DieSchnecke[!]*%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcommands[subcmd_key] and subcommands[subcmd_key].done then
      -- The subcommand has completions. Return them.
      return subcommands[subcmd_key].done(subcmd_arg_lead)
    end
    -- Check if cmdline is a subcommand
    if cmdline:match("^DieSchnecke[!]*%s+%w*$") then
      -- Filter subcommands that match
      local subcommand_keys = vim.tbl_keys(subcommands)
      return vim.iter(subcommand_keys)
          :filter(function(key)
            return key:find(arg_lead) ~= nil
          end)
          :totable()
    end
  end
})
