--- Bytecode parsing module.
-- Provides access to version-specific bytecode parsers.
-- Supports Lua 5.4 and 5.5. Top-level exports (read_bytes, read_file,
-- etc.) are dispatched to the parser matching the running Lua version.
-- Version-specific parsers are also available as bytecode.lua54 and
-- bytecode.lua55.
-- @module llx.bytecode

local version_modules = {
  ['Lua 5.4'] = 'llx.bytecode.lua54',
  ['Lua 5.5'] = 'llx.bytecode.lua55',
}

local current_module = version_modules[_VERSION]
assert(current_module, 'unsupported Lua version for bytecode parsing: ' .. _VERSION)

return require 'llx.flatten_submodules' {
  require(current_module),
  lua54 = require 'llx.bytecode.lua54',
  lua55 = require 'llx.bytecode.lua55',
}
