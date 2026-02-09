local unit = require 'llx.unit'
local llx = require 'llx'

local truthy_module = require 'llx.truthy'

_ENV = unit.create_test_env(_ENV)

describe('truthy', function()
  local truthy = truthy_module.truthy

  it('should return false for nil', function()
    expect(truthy(nil)).to.be_false()
  end)

  it('should return false for false', function()
    expect(truthy(false)).to.be_false()
  end)

  it('should return true for true', function()
    expect(truthy(true)).to.be_true()
  end)

  it('should return false for 0', function()
    expect(truthy(0)).to.be_false()
  end)

  it('should return true for non-zero positive numbers', function()
    expect(truthy(1)).to.be_true()
    expect(truthy(42)).to.be_true()
    expect(truthy(0.5)).to.be_true()
  end)

  it('should return true for negative numbers', function()
    expect(truthy(-1)).to.be_true()
    expect(truthy(-100)).to.be_true()
  end)

  it('should return false for empty string', function()
    expect(truthy('')).to.be_false()
  end)

  it('should return true for non-empty strings', function()
    expect(truthy('a')).to.be_true()
    expect(truthy('hello')).to.be_true()
    expect(truthy(' ')).to.be_true()
  end)

  it('should return false for empty table', function()
    expect(truthy({})).to.be_false()
  end)

  it('should return true for non-empty array table', function()
    expect(truthy({1})).to.be_true()
    expect(truthy({1, 2, 3})).to.be_true()
  end)

  it('should return true for non-empty hash table', function()
    expect(truthy({a = 1})).to.be_true()
  end)

  it('should return true for functions', function()
    expect(truthy(function() end)).to.be_true()
    expect(truthy(print)).to.be_true()
  end)

  it('should return true for coroutines', function()
    local co = coroutine.create(function() end)
    expect(truthy(co)).to.be_true()
  end)
end)

describe('falsey', function()
  local falsey = truthy_module.falsey

  it('should return true for nil', function()
    expect(falsey(nil)).to.be_true()
  end)

  it('should return true for false', function()
    expect(falsey(false)).to.be_true()
  end)

  it('should return false for true', function()
    expect(falsey(true)).to.be_false()
  end)

  it('should return true for 0', function()
    expect(falsey(0)).to.be_true()
  end)

  it('should return false for non-zero numbers', function()
    expect(falsey(1)).to.be_false()
    expect(falsey(-1)).to.be_false()
  end)

  it('should return true for empty string', function()
    expect(falsey('')).to.be_true()
  end)

  it('should return false for non-empty strings', function()
    expect(falsey('a')).to.be_false()
    expect(falsey('hello')).to.be_false()
  end)

  it('should return true for empty table', function()
    expect(falsey({})).to.be_true()
  end)

  it('should return false for non-empty table', function()
    expect(falsey({1})).to.be_false()
    expect(falsey({a = 1})).to.be_false()
  end)

  it('should return false for functions', function()
    expect(falsey(function() end)).to.be_false()
  end)

  it('should be the inverse of truthy for all types', function()
    local truthy = truthy_module.truthy
    local values = {nil, false, true, 0, 1, '', 'a', {}, {1}, function() end}
    for _, v in ipairs(values) do
      expect(falsey(v)).to.be_equal_to(not truthy(v))
    end
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
