--- Platform-specific size constants for Lua 5.4 bytecode.
-- Computes the size of integers on the current platform by shifting bits
-- until overflow. These constants are used during bytecode parsing to
-- correctly read sized fields.
-- @module llx.bytecode.lua54.constants

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local i = 1
local computed_size = 0
repeat
  computed_size = computed_size + 8
  i = i << 8
until i == 0

--- Size of a single bytecode instruction in bytes.
size_of_instruction = 4

--- Size of an integer on the current platform in bits.
size_of_integer = computed_size

--- Size of a number (float) on the current platform in bits.
size_of_number = computed_size

return _M
