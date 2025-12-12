local unit = require 'unit'
local matchers = require 'unit.matchers'

_ENV = unit.create_test_env(_ENV)

local Equals = matchers.equals
local Not = matchers.negate
local Listwise = matchers.listwise
local Tablewise = matchers.tablewise
local GreaterThan = matchers.greater_than
local GreaterThanOrEqual = matchers.greater_than_or_equal

describe('unit test framework', function()
  it('should support EXPECT_TRUE equivalent', function()
    expect(true).to.be_true()
    expect(1 == 1).to.be_true()
  end)

  it('should support EXPECT_FALSE equivalent', function()
    expect(false).to.be_false()
    expect(1 ~= 1).to.be_false()
  end)

  it('should support EXPECT_EQ equivalent', function()
    expect(nil).to.be_equal_to(nil)
    expect(true).to.be_equal_to(true)
    expect(false).to.be_equal_to(false)
    expect(1).to.be_equal_to(1)
    expect("hello, world").to.be_equal_to("hello, world")
    expect(next).to.be_equal_to(next)
    local t = {a=100, b="hello"}
    expect(t).to.be_equal_to(t)
  end)

  it('should support EXPECT_NE equivalent', function()
    expect(1).to_not.be_equal_to(2)
    expect(true).to_not.be_equal_to(false)
    expect(false).to_not.be_equal_to(true)
    expect("hello").to_not.be_equal_to("world")
    expect(next).to_not.be_equal_to(print)
    expect({a=100, b="hello"}).to_not.be_equal_to({a=100})
    expect({b="hello"}).to_not.be_equal_to({a=100, b="hello"})
    expect({a=100, b="hello"}).to_not.be_equal_to({c=100, d="hello"})
    expect({1, 2}).to_not.be_equal_to({1, 2, 3})
    expect({1, 2, 3}).to_not.be_equal_to({2, 3})
    expect({1, 2}).to_not.be_equal_to({2, 3})
  end)

  it('should support Listwise matcher', function()
    expect({1, 2, 3}).to.match(Listwise(Equals, {1, 2, 3}))
    expect({1, 2, 3}).to.match(Listwise(function(v) return Not(Equals(v)) end, {2, 4, 6}))
    expect({1, 2, 3}).to_not.match(Listwise(Equals, {1, 2, 4}))
    expect({1, 2, 3}).to_not.match(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 3}))
    expect({1, 2, 3}).to_not.match(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 4}))
  end)

  it('should support Tablewise matcher', function()
    expect({a=100, b="hello"}).to.match(Tablewise(Equals, {a=100, b="hello"}))
    expect({a=100, b="hello"}).to.match(Tablewise(function(v) return Not(Equals(v)) end, {a=1000, b="goodbye"}))
    expect({a=100, b="hello"}).to_not.match(Tablewise(Equals, {a=100, b="hello", c="world"}))
    expect({a=100, b="hello", c="world"}).to_not.match(Tablewise(Equals, {a=100, b="hello"}))
  end)

  it('should fail when given bad values for be_true', function()
    local success = pcall(function() expect(false).to.be_true() end)
    expect(success).to.be_false()
  end)

  it('should fail when given bad values for be_false', function()
    local success = pcall(function() expect(true).to.be_false() end)
    expect(success).to.be_false()
  end)

  it('should fail when given bad values for be_equal_to', function()
    local success1 = pcall(function() expect(nil).to.be_equal_to(1) end)
    expect(success1).to.be_false()
    local success2 = pcall(function() expect(true).to.be_equal_to(false) end)
    expect(success2).to.be_false()
    local success3 = pcall(function() expect(1).to.be_equal_to(2) end)
    expect(success3).to.be_false()
    local success4 = pcall(function() expect("hello").to.be_equal_to("world") end)
    expect(success4).to.be_false()
    local success5 = pcall(function() expect(next).to.be_equal_to(print) end)
    expect(success5).to.be_false()
    local success6 = pcall(function() expect({a=100, b="hello"}).to.be_equal_to({a=100}) end)
    expect(success6).to.be_false()
    local success7 = pcall(function() expect({b="hello"}).to.be_equal_to({a=100, b="hello"}) end)
    expect(success7).to.be_false()
    local success8 = pcall(function() expect({a=100, b="hello"}).to.be_equal_to({c=100, d="hello"}) end)
    expect(success8).to.be_false()
    local success9 = pcall(function() expect({1, 2}).to.be_equal_to({1, 2, 3}) end)
    expect(success9).to.be_false()
    local success10 = pcall(function() expect({1, 2, 3}).to.be_equal_to({2, 3}) end)
    expect(success10).to.be_false()
    local success11 = pcall(function() expect({1, 2}).to.be_equal_to({2, 3}) end)
    expect(success11).to.be_false()
  end)

  it('should fail when given bad values for be_not_equal_to', function()
    local success1 = pcall(function() expect(nil).to_not.be_equal_to(nil) end)
    expect(success1).to.be_false()
    local success2 = pcall(function() expect(true).to_not.be_equal_to(true) end)
    expect(success2).to.be_false()
    local success3 = pcall(function() expect(false).to_not.be_equal_to(false) end)
    expect(success3).to.be_false()
    local success4 = pcall(function() expect(1).to_not.be_equal_to(1) end)
    expect(success4).to.be_false()
    local success5 = pcall(function() expect("hello, world").to_not.be_equal_to("hello, world") end)
    expect(success5).to.be_false()
    local success6 = pcall(function() expect(next).to_not.be_equal_to(next) end)
    expect(success6).to.be_false()
  end)

  it('should fail when Listwise matcher does not match', function()
    local success = pcall(function() 
      expect({1, 2, 3}).to.match(Listwise(function(v) return Not(Equals(v)) end, {2, 4, 65}))
    end)
    expect(success).to.be_false()
  end)

  it('should fail when GreaterThan matcher does not match', function()
    local success = pcall(function()
      expect({7, 8, 9}).to.match(Listwise(function(v) return GreaterThan(v) end, {12, 2, 3}))
    end)
    expect(success).to.be_false()
  end)

  it('should fail when nested Listwise matcher does not match', function()
    local success = pcall(function()
      expect({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}).to.match(
        Listwise(function(v) return Listwise(GreaterThanOrEqual, v) end,
                 {{1, 2, 3}, {4, 5, 6}, {7, 8, 10}}))
    end)
    expect(success).to.be_false()
  end)
end)

unit.run_unit_tests()
