-- LLDB specifics
-- vim: set et ts=2 sw=2:

local log = require'nvimgdb.log'
local Common = require'nvimgdb.backend.common'
local ParserImpl = require'nvimgdb.parser_impl'

-- @class BackendLldb:Backend @specifics of LLDB
local C = {}
C.__index = C
setmetatable(C, {__index = Common})

-- @return BackendLldb @new instance
function C.new()
  local self = setmetatable({}, C)
  return self
end

-- Create a parser to recognize state changes and code jumps
-- @param actions ParserActions @callbacks for the parser
-- @return ParserImpl @new parser instance
function C.create_parser(actions)
  local P = {}
  P.__index = P
  setmetatable(P, {__index = ParserImpl})

  local self = setmetatable({}, P)
  self:_init(actions)

  local re_prompt = '%s%(lldb%) %(lldb%) $'
  self.add_trans(self.paused, 'Process %d+ resuming', self._paused_continue)
  self.add_trans(self.paused, ' at ([^:]+):(%d+)', self._paused_jump)
  self.add_trans(self.paused, re_prompt, self._query_b)
  self.add_trans(self.running, 'Process %d+ stopped', self._paused)
  self.add_trans(self.running, re_prompt, self._query_b)

  self.state = self.running

  return self
end

-- @param fname string @full path to the source
-- @param proxy Proxy @connection to the side channel
-- @return FileBreakpoints @collection of actual breakpoints
function C.query_breakpoints(fname, proxy)
  log.info("Query breakpoints for " .. fname)
  local resp = proxy:query('info-breakpoints ' .. fname)
  if resp == nil or resp == '' then
    return {}
  end
  -- We expect the proxies to send breakpoints for a given file
  -- as a map of lines to array of breakpoint ids set in those lines.
  local breaks = NvimGdb.vim.fn.json_decode(resp)
  local err = breaks._error
  if err ~= nil then
    log.error("Can't get breakpoints: " .. err)
    return {}
  end
  return breaks
end

-- @type CommandMap
C.command_map = {
  delete_breakpoints = 'breakpoint delete',
  breakpoint = 'b',
  ['until %s'] = 'thread until %s',
  ['info breakpoints'] = 'nvim-gdb-info-breakpoints',
}

-- @return string[]
function C.get_error_formats()
  -- Return the list of errorformats for backtrace, breakpoints.
  -- Breakpoint list is queried specifically with a custom command
  -- nvim-gdb-info-breakpoints, which is only implemented in the proxy.
  return {[[%m\ at\ %f:%l]], [[%f:%l\ %m]]}
end

return C
