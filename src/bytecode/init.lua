--- Bytecode parsing module.
-- Provides access to version-specific bytecode parsers.
-- Supports Lua 5.4 and 5.5.
-- @module llx.bytecode

return require 'llx.flatten_submodules' {
  lua54 = require 'llx.bytecode.lua54',
  lua55 = require 'llx.bytecode.lua55',
}
