-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- The operations whose spelling differs between Lua versions, behind
-- one interface that every supported Lua provides.
--
-- Shared llx code stays in the Lua 5.1 syntax subset and reaches
-- version-specific behaviour only through this module. It loads one
-- layer, chosen for the running interpreter:
--
-- | Interpreter | Layer                | Extends              |
-- |-------------|----------------------|----------------------|
-- | Lua 5.1     | `llx.compat.lua51`   | `llx.compat.portable`|
-- | LuaJIT      | `llx.compat.luajit`  | `llx.compat.lua51`   |
-- | Lua 5.2     | `llx.compat.lua52`   | `llx.compat.portable`|
-- | Lua 5.3+    | `llx.compat.lua53`   | `llx.compat.lua52`   |
--
-- A layer is loaded only on the versions in its row, so it may use
-- their syntax and globals. The functions every layer provides are
-- documented in llx.compat.portable, llx.compat.lua51 and
-- llx.compat.lua52; the bitwise operations work on 64-bit integers on
-- Lua 5.3+ and on unsigned 32-bit integers everywhere else
-- (`integer_bits`).
--
-- @module llx.compat

-- rawget, so a host whose global table raises on a missing name can
-- still load llx on an interpreter without `jit`.
local luajit = type(rawget(_G, 'jit')) == 'table'
local version = _VERSION:match('^Lua (%d+%.%d+)$') or _VERSION

-- Each layer's chain, base first; the last entry is the one loaded.
local layers
if luajit then
  layers = {'llx.compat.portable', 'llx.compat.lua51', 'llx.compat.luajit'}
elseif version == '5.1' then
  layers = {'llx.compat.portable', 'llx.compat.lua51'}
elseif version == '5.2' then
  layers = {'llx.compat.portable', 'llx.compat.lua52'}
else
  layers = {'llx.compat.portable', 'llx.compat.lua52', 'llx.compat.lua53'}
end
local layer = layers[#layers]

local M = {}
for name, value in pairs(require(layer)) do
  M[name] = value
end

--- The running Lua's version, such as '5.4'. LuaJIT reports '5.1'.
M.lua_version = version

--- Whether the interpreter is LuaJIT.
M.luajit = luajit

--- The module name of the layer in use.
M.layer = layer

--- The layer modules this interpreter loads, base first. A layer not
-- listed here is for another interpreter and may not load.
M.layers = layers

return M
