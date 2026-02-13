--- Lua 5.5 bytecode instruction decoder.
-- Lua 5.5.0 uses the same instruction format and opcode set as Lua 5.4,
-- so this module re-exports the 5.4 instructions directly.
-- @module llx.bytecode.lua55.instructions

return require 'llx.bytecode.lua54.instructions'
