local unit = require 'llx.unit'
local llx = require 'llx'

local constants = require 'llx.bytecode.lua54.constants'

_ENV = unit.create_test_env(_ENV)

describe('bytecode constants', function()
  it('size_of_instruction should be 4', function()
    expect(constants.size_of_instruction).to.be_equal_to(4)
  end)

  it('size_of_integer should be a positive number and multiple of 8', function()
    expect(constants.size_of_integer).to.be_greater_than(0)
    expect(constants.size_of_integer % 8).to.be_equal_to(0)
  end)

  it('size_of_number should equal size_of_integer', function()
    expect(constants.size_of_number).to.be_equal_to(constants.size_of_integer)
  end)

  it('size_of_integer should be at least 32', function()
    expect(constants.size_of_integer).to.be_greater_than_or_equal(32)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
