-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- The llx.compat layer for Lua 5.3 and later: Lua 5.2's, with native
-- integers and the integer operators.
--
-- Loaded only on Lua 5.3 and later. It is the one source in llx that
-- may use the integer operators (`//`, `&`, `|`, `~`, `<<`, `>>`),
-- which no earlier Lua can parse.
--
-- @module llx.compat.lua53

local lua52 = require 'llx.compat.lua52'

local M = {}
for name, value in pairs(lua52) do
  M[name] = value
end

M.integer_bits = 64
M.has_integer_subtype = true
M.math_type = math.type

function M.equals(a, b) return a == b end

M.unpack = table.unpack
M.ipairs = ipairs

function M.add_name_tostring(metatable)
  return metatable
end

function M.band(a, b) return a & b end
function M.bor(a, b) return a | b end
function M.bxor(a, b) return a ~ b end
function M.bnot(a) return ~a end
function M.lshift(a, n) return a << n end
function M.rshift(a, n) return a >> n end
function M.floordiv(a, b) return a // b end

function M.u32_mul(a, b)
  return (a * b) & 0xFFFFFFFF
end

function M.pack_double(value)
  return string.pack('<d', value)
end

function M.add_integer_operator_metamethods(metatable, unwrap)
  metatable.__idiv = function(a, b) return unwrap(a) // unwrap(b) end
  metatable.__band = function(a, b) return unwrap(a) & unwrap(b) end
  metatable.__bor = function(a, b) return unwrap(a) | unwrap(b) end
  metatable.__bxor = function(a, b) return unwrap(a) ~ unwrap(b) end
  metatable.__shl = function(a, b) return unwrap(a) << unwrap(b) end
  metatable.__shr = function(a, b) return unwrap(a) >> unwrap(b) end
  metatable.__bnot = function(a) return ~unwrap(a) end
  return metatable
end

return M
