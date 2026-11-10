-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Loads llx from this checkout into a world of its own whose global
-- table is shaped as a host that locks its global table makes it:
-- `_G` names an empty proxy that reads the globals through from a table
-- beneath it, raises on a name that table does not hold, refuses every
-- write, and protects its metatable. `rawget(_G, name)` finds none of
-- the globals there.
--
-- A sandboxed world holds only the globals a sandboxing host keeps:
-- no debug, io or os library and no loaders (`load`, `loadfile`,
-- `loadstring`, `dofile`).
--
-- Loaded by path rather than required: a per-file run resolves only
-- the installed llx.* modules, not llx.tests.*.

local compat = require 'llx.compat'

local M = {}

local SANDBOX_GLOBALS = {
  '_VERSION', 'assert', 'bit', 'collectgarbage', 'coroutine', 'error',
  'gcinfo', 'getfenv', 'getmetatable', 'ipairs', 'jit', 'math',
  'newproxy', 'next', 'pairs', 'pcall', 'print', 'rawequal', 'rawget',
  'rawlen', 'rawset', 'select', 'setfenv', 'setmetatable', 'string',
  'table', 'tonumber', 'tostring', 'type', 'unpack', 'utf8', 'warn',
  'xpcall',
}

local SANDBOX_MODULES = {
  'bit', 'coroutine', 'jit', 'math', 'string', 'table', 'utf8',
}

-- The library tables llx extends in place when it loads, so each world
-- gets copies of its own and the running suite keeps its originals.
local EXTENDED_LIBRARIES = {'string', 'table'}

--- The message the world's global table raises for a write.
M.WRITE_REFUSED = 'global writes disallowed'

--- The value the world's protected metatable shows to getmetatable.
M.PROTECTED = 'locked'

-- src/, found from this file's own path so the aggregate runner and a
-- standalone run load the same sources.
local function source_root()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  return (path:match('^(.*[/\\])') or '') .. '../../src/'
end

local function file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

-- The checkout source of an llx module, or nil for any other module.
local function module_path(name)
  local relative
  if name == 'llx' then
    relative = 'init'
  else
    relative = name:match('^llx%.(.+)$')
  end
  if relative == nil then return nil end
  local base = source_root() .. relative:gsub('%.', '/')
  if file_exists(base .. '.lua') then return base .. '.lua' end
  if file_exists(base .. '/init.lua') then return base .. '/init.lua' end
  error("no llx source for module '" .. name .. "'", 3)
end

-- The fields of `t`, read raw, in a new table without a metatable.
local function raw_copy(t)
  local copy = {}
  for key, value in next, t do
    copy[key] = value
  end
  return copy
end

--- Builds a world.
-- @param options A table, or nil for the defaults:
--   `sandbox` (boolean) keeps only the sandbox's globals, so the world
--   has no debug library;
--   `hide_jit` (boolean) leaves `jit` out of the globals while
--   `package.loaded.jit` still holds it, as on LuaJIT;
--   `unprotected` (boolean) leaves the lock's metatable without a
--   `__metatable` field.
-- @return A table with `globals` (the lock, which `_G` names),
--   `metatable` (the lock's real metatable), `backing` (the table the
--   lock reads through) and `require` (which loads llx.* from src/ into
--   the world; any other module is one the host loaded, or not found).
function M.new(options)
  options = options or {}
  local backing = {}
  if options.sandbox then
    for _, name in ipairs(SANDBOX_GLOBALS) do
      backing[name] = rawget(_G, name)
    end
  else
    for name, value in pairs(_G) do
      backing[name] = value
    end
  end
  for _, name in ipairs(EXTENDED_LIBRARIES) do
    backing[name] = raw_copy(_G[name])
  end
  if options.hide_jit then
    backing.jit = nil
  end

  local host_modules = {}
  if options.sandbox then
    for _, name in ipairs(SANDBOX_MODULES) do
      host_modules[name] = package.loaded[name]
    end
  else
    for name, value in pairs(package.loaded) do
      if name ~= 'llx' and not name:find('^llx%.') then
        host_modules[name] = value
      end
    end
  end
  for _, name in ipairs(EXTENDED_LIBRARIES) do
    host_modules[name] = backing[name]
  end

  local metatable = {
    __index = function(_, name)
      local value = backing[name]
      if value == nil then
        error('attempting to retrieve undefined variable '
              .. tostring(name), 2)
      end
      return value
    end,
    __newindex = function()
      error(M.WRITE_REFUSED, 2)
    end,
  }
  if not options.unprotected then
    metatable.__metatable = M.PROTECTED
  end
  local globals = setmetatable({}, metatable)

  -- The host opened these, so they are loaded before any require.
  local loaded = raw_copy(host_modules)
  loaded._G = globals
  local world_package = {
    loaded = loaded,
    preload = {},
    path = package.path,
    cpath = package.cpath,
    config = package.config,
  }
  loaded.package = world_package
  backing._G = globals
  backing.package = world_package

  local function world_require(name)
    local value = loaded[name]
    if value ~= nil then return value end
    local path = module_path(name)
    if path == nil then
      error("module '" .. name .. "' not found", 2)
    end
    local chunk = assert(compat.loadfile(path, 't', globals))
    value = chunk(name, path)
    if value == nil then value = loaded[name] end
    if value == nil then value = true end
    loaded[name] = value
    return value
  end
  backing.require = world_require

  return {
    globals = globals,
    metatable = metatable,
    backing = backing,
    require = world_require,
  }
end

--- Requires a module in a world, putting back the metatable every
-- string shares, which llx extends when it loads.
-- @param world A world from `new`.
-- @param name The module to require.
-- @return true and the module, or false and what the require raised.
function M.require(world, name)
  local string_metatable = getmetatable('')
  local saved = raw_copy(string_metatable)
  local ok, result = pcall(world.require, name)
  for key in next, raw_copy(string_metatable) do
    rawset(string_metatable, key, saved[key])
  end
  for key, value in next, saved do
    rawset(string_metatable, key, value)
  end
  return ok, result
end

return M
