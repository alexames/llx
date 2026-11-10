-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- The llx.compat layer for Lua 5.1, which LuaJIT's layer extends.
--
-- Loaded only on Lua 5.1 and LuaJIT, so it may name their globals
-- (setfenv, getfenv, loadstring, unpack) directly. It must stay in the
-- Lua 5.1 syntax subset.
--
-- @module llx.compat.lua51

local portable = require 'llx.compat.portable'

local M = {}
for name, value in pairs(portable) do
  M[name] = value
end

local debug_library = portable.debug_library
local raw_getmetatable = portable.raw_getmetatable
local optional_global = portable.optional_global
local load_function = optional_global(function() return load end)
local loadstring_function = optional_global(function() return loadstring end)
local loadfile_function = optional_global(function() return loadfile end)

-- The metamethod a value's metatable holds under `name`, read the way
-- Lua 5.2's pairs and # read it: from the real metatable, bypassing a
-- __metatable field, and without invoking __index.
local function metamethod(value, name)
  local metatable = raw_getmetatable(value)
  if type(metatable) ~= 'table' then return nil end
  return rawget(metatable, name)
end

--- Packs its arguments into a table with the count in field `n`, as
-- table.pack does.
-- @param ... The values to pack.
-- @return A new table holding the values at 1..n.
function M.pack(...)
  return {n = select('#', ...), ...}
end

--- Loads a chunk with Lua 5.2's load signature. nil where the host
-- left out `loadstring`, as a sandbox does.
-- @param chunk A string, or a function returning successive pieces.
-- @param chunkname The name error messages report for the chunk.
-- @param mode Ignored: Lua 5.1 cannot refuse text or binary chunks.
-- @param env The chunk's environment; nil keeps the global one.
-- @return The compiled function, or nil and an error message.
function M.load(chunk, chunkname, mode, env)
  local loaded, err
  if type(chunk) == 'string' then
    loaded, err = loadstring_function(chunk, chunkname)
  elseif load_function then
    loaded, err = load_function(chunk, chunkname)
  else
    return nil, 'loading a chunk from a function needs load'
  end
  if loaded and env ~= nil then
    setfenv(loaded, env)
  end
  return loaded, err
end

--- Loads a file with Lua 5.2's loadfile signature. nil where the host
-- left out `loadfile`, as a sandbox does.
-- @param path The file to load; nil reads standard input.
-- @param mode Ignored: Lua 5.1 cannot refuse text or binary chunks.
-- @param env The chunk's environment; nil keeps the global one.
-- @return The compiled function, or nil and an error message.
function M.loadfile(path, mode, env)
  local loaded, err = loadfile_function(path)
  if loaded and env ~= nil then
    setfenv(loaded, env)
  end
  return loaded, err
end

if not loadstring_function then M.load = nil end
if not loadfile_function then M.loadfile = nil end

--- Makes `env` the environment of a running chunk, which is what
-- `local _ENV = env` at a chunk's top level does lexically on Lua 5.2+.
-- Closures the chunk creates afterwards inherit it; ones it already
-- created keep theirs.
--
-- Only a chunk's main function is changed: a function that merely
-- calls an environment constructor to inspect the result keeps its own
-- environment. Without the debug library every caller is changed.
-- @param env The environment table.
-- @param level The function to change, counted as for error(): 1 is
--   the function that calls install_environment.
function M.install_environment(env, level)
  local info = debug_library and debug_library.getinfo
      and debug_library.getinfo(level + 1, 'S')
  if info == nil or info.what == 'main' then
    setfenv(level + 1, env)
  end
end

--- The environment of a running function.
-- @param level Counted as for error(): 1 is the function that calls
--   environment_of.
-- @return The function's environment table.
function M.environment_of(level)
  -- Not `return getfenv(level + 1)`: LuaJIT drops this frame for a C
  -- function called in tail position, and getfenv would count from the
  -- caller instead.
  local environment = getfenv(level + 1)
  return environment
end

--- The environment of the chunk that defines `read_env`: the table
-- `_ENV` names there on Lua 5.2+.
--
-- `read_env` is not called. Lua 5.1 has no _ENV, so its body would
-- read a global of that name, which a global table that refuses
-- missing names raises on. Its own environment, inherited from the
-- chunk, is the answer instead.
-- @param read_env A function written `function() return _ENV end` in
--   the chunk whose environment is wanted.
-- @return The chunk's environment table.
function M.defining_environment(read_env)
  return getfenv(read_env)
end

--- Iterates a value, honouring a __pairs metamethod as Lua 5.2+ does.
-- @param value The table (or object with __pairs) to iterate.
-- @return An iterator function, state and initial control value.
function M.pairs(value)
  local handler = metamethod(value, '__pairs')
  if handler then
    return handler(value)
  end
  return next, value, nil
end

--- The length of a value, honouring a __len metamethod on a table as
-- Lua 5.2+ does.
-- @param value A string, table, or object with __len.
-- @return The length.
function M.len(value)
  if type(value) == 'table' then
    local handler = metamethod(value, '__len')
    if handler then
      return handler(value)
    end
  end
  return #value
end

--- Unpacks a list, as Lua 5.3's table.unpack does: elements are read
-- through __index and the default count through __len.
-- @param list The table to unpack.
-- @param first The first index; defaults to 1.
-- @param last The last index; defaults to the list's length.
-- @return list[first], ..., list[last].
M.unpack = portable.make_unpack(unpack, M.len)

--- The number of fixed parameters a function declares and whether it
-- is variadic, as debug.getinfo(f, 'u') reports them on Lua 5.2+.
--
-- Lua 5.1 does not report them, so they are read from the header of
-- the function's string.dump. A C function cannot be dumped and is
-- reported as 5.2 reports one: no fixed parameters, variadic.
-- @param func The function to inspect.
-- @return The fixed parameter count and whether the function is
--   variadic.
function M.function_parameters(func)
  local dumped, chunk = pcall(string.dump, func)
  if not dumped then
    return 0, true
  end
  -- The 12-byte header records sizeof(int) at byte 8 and sizeof(size_t)
  -- at byte 9, and whether integers are little-endian at byte 7.
  local little_endian = chunk:byte(7) == 1
  local int_size, size_t_size = chunk:byte(8), chunk:byte(9)
  local source_length = 0
  for i = 1, size_t_size do
    local index = little_endian and (13 + size_t_size - i) or (12 + i)
    source_length = source_length * 256 + chunk:byte(index)
  end
  -- After the source come linedefined and lastlinedefined (ints), then
  -- nups, numparams and is_vararg, one byte each.
  local numparams_at = 13 + size_t_size + source_length + 2 * int_size + 1
  local numparams = chunk:byte(numparams_at)
  local vararg_flags = chunk:byte(numparams_at + 1)
  -- VARARG_ISVARARG is bit 1 of is_vararg.
  return numparams, vararg_flags % 4 >= 2
end

--- Formats a string as Lua 5.2+'s string.format does, where `%s`
-- converts any value with tostring. Lua 5.1's accepts only strings and
-- numbers there, so every other argument is converted first.
-- @param format A string.format format string.
-- @param ... The values to format.
-- @return The formatted string.
function M.format(format, ...)
  local values = M.pack(...)
  for i = 1, values.n do
    local value_type = type(values[i])
    if value_type ~= 'number' and value_type ~= 'string' then
      values[i] = tostring(values[i])
    end
  end
  return string.format(format, unpack(values, 1, values.n))
end

--- The list of package searchers require consults, in order.
M.package_searchers = package.loaders

--- Whether `<` and `<=` between a table and a number reach the
-- table's __lt and __le. Lua 5.1 raises instead, and compares two
-- tables only when both metatables hold the same handler.
M.order_metamethods_mix_types = false

return M
