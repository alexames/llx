--- Lua 5.4 bytecode parsing module.
-- Aggregates all Lua 5.4 bytecode submodules into a single entry point.
-- Provides bytecode reading, instruction decoding, opcode definitions,
-- type tags, and utility functions for bytecode inspection.
-- @module llx.bytecode.lua54

return require 'llx.flatten_submodules' {
  require 'llx.bytecode.lua54.bcode',
  require 'llx.bytecode.lua54.bytestream',
  require 'llx.bytecode.lua54.constants',
  require 'llx.bytecode.lua54.enum',
  require 'llx.bytecode.lua54.instructions',
  require 'llx.bytecode.lua54.opcodes',
  require 'llx.bytecode.lua54.typetags',
  require 'llx.bytecode.lua54.util',
}
