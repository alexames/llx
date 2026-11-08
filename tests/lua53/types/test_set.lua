-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- The Set tests that need the Lua 5.3 integer operators,
-- which no earlier Lua can parse. tests/init.lua loads this file only
-- on Lua 5.3 and later.


local llx = require 'llx'
local unit = require 'llx.unit'
local Set = require 'llx.types.set' . Set

local describe = unit.describe
local it = unit.it
local expect = unit.expect


describe('Set (Lua 5.3+ operators)', function()
  it('should support | operator', function()
    local a = Set{1, 2}
    local b = Set{2, 3}
    local result = a | b
    expect(#result).to.be_equal_to(3)
  end)

  it('should support & operator', function()
    local a = Set{1, 2, 3}
    local b = Set{2, 3}
    local result = a & b
    expect(#result).to.be_equal_to(2)
  end)

  it('should support ~ operator', function()
    local a = Set{1, 2}
    local b = Set{2, 3}
    local result = a ~ b
    expect(#result).to.be_equal_to(2)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end
