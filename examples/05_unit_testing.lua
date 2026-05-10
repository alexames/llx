-- examples/05_unit_testing.lua
-- BDD-style unit tests with mocks. Run this file directly to
-- execute the tests.

local llx = require 'llx'
local unit = require 'llx.unit'

-- The unit env exposes describe, it, expect, before_each, etc.
_ENV = unit.create_test_env(_ENV)

-- Code under test.
local Calculator = llx.class 'Calculator' {
  add = function(self, a, b) return a + b end,
  divide = function(self, a, b)
    if b == 0 then error('division by zero') end
    return a / b
  end,
}

describe('Calculator', function()
  local calc

  before_each(function()
    calc = Calculator()
  end)

  it('should add two numbers', function()
    expect(calc:add(2, 3)).to.be_equal_to(5)
  end)

  it('should add negatives', function()
    expect(calc:add(-2, -3)).to.be_equal_to(-5)
  end)

  it('should divide', function()
    expect(calc:divide(10, 2)).to.be_equal_to(5)
  end)

  it('should raise on divide-by-zero', function()
    expect(function() calc:divide(1, 0) end).to.throw()
  end)
end)

-- Mocks: spy_on wraps an existing method; Mock creates a new fn.
describe('mocks', function()
  it('Mock records calls', function()
    local m = unit.Mock()
    m('first')
    m('second', 42)
    expect(#m.calls).to.be_equal_to(2)
    expect(m.calls[2][1]).to.be_equal_to('second')
  end)

  it('spy_on tracks an existing method without replacing it', function()
    local obj = {greet = function(self, name) return 'hi ' .. name end}
    local spy = unit.spy_on(obj, 'greet')
    obj:greet('Alice')
    expect(#spy.calls).to.be_equal_to(1)
    unit.restore_all_spies()
  end)
end)

-- Run the tests if this file is executed directly.
if llx.main_file() then
  unit.run_unit_tests()
end
