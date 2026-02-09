local unit = require 'llx.unit'
local llx = require 'llx'

_ENV = unit.create_test_env(_ENV)

-- The bytecode module uses local requires (e.g., require 'bcode') and
-- src/bytecode/main.lua contains @decorator syntax requiring a custom
-- Lua preprocessor. Full unit testing requires binary bytecode fixtures
-- and the preprocessor infrastructure.
--
-- Modules: bcode, bytestream, constants, enum, instructions, main,
-- opcodes, typetags, util

describe('bytecode', function()
  it.todo('bytestream: read integers, floats, varints, and strings')
  it.todo('constants: platform size constants')
  it.todo('enum: bytecode-local enum creation')
  it.todo('typetags: Lua type tag lookup')
  it.todo('opcodes: opcode name resolution')
  it.todo('instructions: decode 32-bit bytecode instructions')
  it.todo('bcode: parse bytecode files and function prototypes')
  it.todo('util: dump and compare bytecode output')
end)

if llx.main_file() then
  unit.run_unit_tests()
end
