-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- The llx.compat layer for LuaJIT: Lua 5.1's, with the bitwise
-- operations taken from LuaJIT's `bit` library and doubles encoded
-- through the FFI.
--
-- Loaded only on LuaJIT.
--
-- @module llx.compat.luajit

local bit = require 'bit'

local lua51 = require 'llx.compat.lua51'

local M = {}
for name, value in pairs(lua51) do
  M[name] = value
end

local TWO_32 = 4294967296

-- The bit library returns signed 32-bit results; llx.compat promises
-- unsigned ones on every 32-bit layer.
local function unsigned(value)
  return value % TWO_32
end

function M.band(a, b) return unsigned(bit.band(a, b)) end
function M.bor(a, b) return unsigned(bit.bor(a, b)) end
function M.bxor(a, b) return unsigned(bit.bxor(a, b)) end
function M.bnot(a) return unsigned(bit.bnot(a)) end

-- bit.lshift and bit.rshift reduce the count modulo 32; the portable
-- versions treat 32 or more as shifting every bit out, and so do these.
function M.lshift(a, n)
  if n < 0 then return M.rshift(a, -n) end
  if n >= 32 then return 0 end
  return unsigned(bit.lshift(a, n))
end

function M.rshift(a, n)
  if n < 0 then return M.lshift(a, -n) end
  if n >= 32 then return 0 end
  return unsigned(bit.rshift(a, n))
end

--- The number of fixed parameters a function declares and whether it
-- is variadic, which LuaJIT's debug.getinfo(f, 'u') reports as Lua
-- 5.2's does. Raises where the host left the debug library out.
-- @param func The function to inspect.
-- @return The fixed parameter count and whether the function is
--   variadic.
function M.function_parameters(func)
  local debug_library = lua51.debug_library
  if not debug_library then
    error('llx.compat.function_parameters needs the debug library', 2)
  end
  local info = debug_library.getinfo(func, 'u')
  return info.nparams, info.isvararg
end

local ffi_loaded, ffi = pcall(require, 'ffi')
if ffi_loaded and ffi.abi('le') then
  local box = ffi.new('double[1]')
  function M.pack_double(value)
    box[0] = value
    return ffi.string(box, 8)
  end
end

return M
