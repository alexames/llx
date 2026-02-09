-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.types.list'

_ENV = unit.create_test_env(_ENV)

describe('functional combinators (tier 2)', function()
  describe('curry', function()
    it('should auto-curry a two-argument function', function()
      local add = llx.functional.curry(function(a, b) return a + b end, 2)
      expect(add(1)(2)).to.be_equal_to(3)
    end)

    it('should allow calling with all arguments at once', function()
      local add = llx.functional.curry(function(a, b) return a + b end, 2)
      expect(add(1, 2)).to.be_equal_to(3)
    end)

    it('should curry a three-argument function', function()
      local add3 = llx.functional.curry(function(a, b, c) return a + b + c end, 3)
      expect(add3(1)(2)(3)).to.be_equal_to(6)
    end)

    it('should allow partial application with multiple args', function()
      local add3 = llx.functional.curry(function(a, b, c) return a + b + c end, 3)
      expect(add3(1, 2)(3)).to.be_equal_to(6)
    end)
  end)

  describe('flip', function()
    it('should swap the first two arguments', function()
      local sub = function(a, b) return a - b end
      local flipped = llx.functional.flip(sub)
      expect(flipped(3, 10)).to.be_equal_to(7)
    end)

    it('should pass remaining arguments through', function()
      local f = function(a, b, c) return a .. b .. c end
      local flipped = llx.functional.flip(f)
      expect(flipped('x', 'y', 'z')).to.be_equal_to('yxz')
    end)
  end)

  describe('negate', function()
    it('should return the logical negation of a predicate', function()
      local is_even = function(x) return x % 2 == 0 end
      local is_odd = llx.functional.negate(is_even)
      expect(is_odd(3)).to.be_true()
      expect(is_odd(4)).to.be_false()
    end)
  end)

  describe('once', function()
    it('should call the function only once', function()
      local count = 0
      local f = llx.functional.once(function()
        count = count + 1
        return count
      end)
      expect(f()).to.be_equal_to(1)
      expect(f()).to.be_equal_to(1)
      expect(f()).to.be_equal_to(1)
      expect(count).to.be_equal_to(1)
    end)

    it('should pass arguments on the first call', function()
      local f = llx.functional.once(function(x) return x * 2 end)
      expect(f(5)).to.be_equal_to(10)
      expect(f(99)).to.be_equal_to(10)
    end)
  end)

  describe('constant', function()
    it('should always return the same value', function()
      local five = llx.functional.constant(5)
      expect(five()).to.be_equal_to(5)
      expect(five(1, 2, 3)).to.be_equal_to(5)
    end)

    it('should work with nil', function()
      local nothing = llx.functional.constant(nil)
      expect(nothing()).to.be_nil()
    end)
  end)

  describe('identity', function()
    it('should return its argument unchanged', function()
      expect(llx.functional.identity(42)).to.be_equal_to(42)
    end)

    it('should return multiple arguments', function()
      local a, b, c = llx.functional.identity(1, 2, 3)
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
