-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- The llx.compat layer for Lua 5.2, which the 5.3+ layer extends.
--
-- Loaded only on Lua 5.2 and later. It must stay in the Lua 5.2 syntax
-- subset, so the 5.3 integer operators belong in llx.compat.lua53.
--
-- @module llx.compat.lua52

local portable = require 'llx.compat.portable'

local M = {}
for name, value in pairs(portable) do
  M[name] = value
end

-- Raises, naming the function, when the host left the debug library out.
local function require_debug(function_name)
  local debug_library = portable.debug_library
  if not debug_library then
    error('llx.compat.' .. function_name .. ' needs the debug library', 3)
  end
  return debug_library
end

M.pack = table.pack
M.format = string.format
-- nil where the host left them out, as a sandbox does.
M.load = portable.optional_global(function() return load end)
M.loadfile = portable.optional_global(function() return loadfile end)
M.pairs = pairs
M.package_searchers = package.searchers
M.order_metamethods_mix_types = true

--- A no-op: `local _ENV = env` installs an environment lexically.
-- @param env Unused.
-- @param level Unused.
function M.install_environment(env, level)
end

--- The environment of a running function: the value of its _ENV
-- upvalue, or nil when it has none.
--
-- Needs the debug library, and raises without it. A chunk asking for
-- its own environment can use defining_environment, which does not.
-- @param level Counted as for error(): 1 is the function that calls
--   environment_of.
-- @return The environment table, or nil.
function M.environment_of(level)
  local debug_library = require_debug('environment_of')
  local info = debug_library.getinfo(level + 1, 'f')
  local index = 1
  while true do
    local name, value = debug_library.getupvalue(info.func, index)
    if name == nil then return nil end
    if name == '_ENV' then return value end
    index = index + 1
  end
end

--- The environment of the chunk that defines `read_env`: the table
-- `_ENV` names there, which `read_env` returns. Unlike
-- environment_of, it needs no debug library.
-- @param read_env A function written `function() return _ENV end` in
--   the chunk whose environment is wanted.
-- @return The chunk's environment table.
function M.defining_environment(read_env)
  return read_env()
end

--- The number of fixed parameters a function declares and whether it
-- is variadic, as debug.getinfo(f, 'u') reports them. Raises where the
-- host left the debug library out.
-- @param func The function to inspect.
-- @return The fixed parameter count and whether the function is
--   variadic.
function M.function_parameters(func)
  local info = require_debug('function_parameters').getinfo(func, 'u')
  return info.nparams, info.isvararg
end

--- The length of a value, as # computes it.
-- @param value A string, table, or object with __len.
-- @return The length.
function M.len(value)
  return #value
end

-- 5.2's table.unpack reads elements raw; 5.3's reads them through
-- __index, which the 5.3 layer gets by using table.unpack directly.
M.unpack = portable.make_unpack(table.unpack, M.len)

-- bit32 is standard in 5.2 and present in 5.3 only when it is built
-- with LUA_COMPAT_BITLIB; the 5.3 layer replaces these anyway.
local bit32_library =
    portable.optional_global(function() return bit32 end)
if bit32_library then
  M.band = bit32_library.band
  M.bor = bit32_library.bor
  M.bxor = bit32_library.bxor
  M.bnot = bit32_library.bnot
  M.lshift = function(a, n)
    if n >= 32 or n <= -32 then return 0 end
    return bit32_library.lshift(a, n)
  end
  M.rshift = function(a, n)
    if n >= 32 or n <= -32 then return 0 end
    return bit32_library.rshift(a, n)
  end
end

return M
