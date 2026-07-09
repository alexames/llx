-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local ExceptionGroup =
    require 'llx.exceptions.exception_group' . ExceptionGroup

local _ENV, _M = environment.create_module_environment()

--- Raised when no declaration of an overload set accepts a call.
--
-- An ExceptionGroup whose members are the per-candidate precondition
-- failures (InvalidArgumentException or a subclass), in declaration
-- order, so handlers can inspect why each candidate was rejected via
-- the inherited `exception_list` field. `candidates` holds the
-- corresponding human-readable signature descriptions (plain strings,
-- e.g. '(Integer, Integer) -> (Integer)'), also in declaration order,
-- and `what` lists every candidate alongside its failure.
OverloadResolutionException =
    class 'OverloadResolutionException' : extends(ExceptionGroup) {
  __init = function(self, candidates, exception_list, level)
    ExceptionGroup.__init(self, exception_list, (level or 1) + 1)
    self.candidates = candidates
    local lines = {string.format(
        'no overload matched the call; %d candidate(s) rejected:',
        #exception_list)}
    for i, exception in ipairs(exception_list) do
      local reason = exception.what:gsub('\n', '\n    ')
      lines[#lines + 1] = string.format(
          '  candidate %d %s: %s', i, candidates[i] or '?', reason)
    end
    self.what = table.concat(lines, '\n')
  end,
}

return _M
