--- Lua 5.5 bytecode parsing module.
-- Aggregates all Lua 5.5 bytecode submodules into a single entry point.
-- Provides bytecode reading, instruction decoding, opcode definitions,
-- type tags, and utility functions for bytecode inspection.
-- @module llx.bytecode.lua55

return require 'llx.flatten_submodules' {
  require 'llx.bytecode.lua55.bcode',
  require 'llx.bytecode.lua55.bytestream',
  require 'llx.bytecode.lua55.constants',
  require 'llx.bytecode.lua55.enum',
  require 'llx.bytecode.lua55.instructions',
  require 'llx.bytecode.lua55.opcodes',
  require 'llx.bytecode.lua55.typetags',
  require 'llx.bytecode.lua55.util',
}
