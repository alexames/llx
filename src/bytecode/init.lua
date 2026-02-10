--- Bytecode parsing module.
-- Provides access to version-specific bytecode parsers.
-- Currently supports Lua 5.4.
-- @module llx.bytecode

return require 'llx.flatten_submodules' {
  lua54 = require 'llx.bytecode.lua54',
}
