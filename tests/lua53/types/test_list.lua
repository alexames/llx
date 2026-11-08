-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- The ListTest tests that need the Lua 5.3 integer operators,
-- which no earlier Lua can parse. tests/init.lua loads this file only
-- on Lua 5.3 and later.

local unit = require 'llx.unit'
local llx = require 'llx'

local List = llx.List

local _ENV = unit.create_test_env(_ENV)

describe('ListTest (Lua 5.3+ operators)', function()
  it('should return same list when shifting right by 0', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 0).to.be_equal_to(List{'a', 'b', 'c', 'd', 'e'})
  end)

  it('should return shifted list when shifting right by 1', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 1).to.be_equal_to(List{'e', 'a', 'b', 'c', 'd'})
  end)

  it('should return shifted list when shifting right by 2', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 2).to.be_equal_to(List{'d', 'e', 'a', 'b', 'c'})
  end)

  it('should return shifted list when shifting right by 3', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 3).to.be_equal_to(List{'c', 'd', 'e', 'a', 'b'})
  end)

  it('should return shifted list when shifting right by 4', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 4).to.be_equal_to(List{'b', 'c', 'd', 'e', 'a'})
  end)

  it('should return same list when shifting left by 0', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 0).to.be_equal_to(List{'a', 'b', 'c', 'd', 'e'})
  end)

  it('should return shifted list when shifting left by 1', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 1).to.be_equal_to(List{'b', 'c', 'd', 'e', 'a'})
  end)

  it('should return shifted list when shifting left by 2', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 2).to.be_equal_to(List{'c', 'd', 'e', 'a', 'b'})
  end)

  it('should return shifted list when shifting left by 3', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 3).to.be_equal_to(List{'d', 'e', 'a', 'b', 'c'})
  end)

  it('should return shifted list when shifting left by 4', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 4).to.be_equal_to(List{'e', 'a', 'b', 'c', 'd'})
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end
