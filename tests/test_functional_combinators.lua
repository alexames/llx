-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.operators'
require 'llx.types.list'
require 'llx.types.table'
require 'llx.types.string'

_ENV = unit.create_test_env(_ENV)

describe('functional combinators', function()
  describe('partial', function()
    it('should pre-fill arguments from the left', function()
      local function add(a, b) return a + b end
      local add5 = llx.functional.partial(add, 5)
      expect(add5(3)).to.be_equal_to(8)
    end)

    it('should work with multiple pre-filled arguments', function()
      local function add3(a, b, c) return a + b + c end
      local add_1_2 = llx.functional.partial(add3, 1, 2)
      expect(add_1_2(7)).to.be_equal_to(10)
    end)

    it('should work with no pre-filled arguments', function()
      local function double(x) return x * 2 end
      local same = llx.functional.partial(double)
      expect(same(4)).to.be_equal_to(8)
    end)

    it('should preserve multiple return values', function()
      local function swap(a, b) return b, a end
      local swap_with_1 = llx.functional.partial(swap, 1)
      local x, y = swap_with_1(2)
      expect(x).to.be_equal_to(2)
      expect(y).to.be_equal_to(1)
    end)
  end)

  describe('compose', function()
    it('should compose two functions right-to-left', function()
      local function double(x) return x * 2 end
      local function inc(x) return x + 1 end
      local double_then_inc = llx.functional.compose(inc, double)
      -- compose(inc, double)(3) = inc(double(3)) = inc(6) = 7
      expect(double_then_inc(3)).to.be_equal_to(7)
    end)

    it('should compose three functions right-to-left', function()
      local function double(x) return x * 2 end
      local function inc(x) return x + 1 end
      local function negate(x) return -x end
      local composed = llx.functional.compose(negate, inc, double)
      -- compose(negate, inc, double)(3) = negate(inc(double(3))) = negate(inc(6)) = negate(7) = -7
      expect(composed(3)).to.be_equal_to(-7)
    end)

    it('should pass multiple arguments to the rightmost function', function()
      local function add(a, b) return a + b end
      local function double(x) return x * 2 end
      local composed = llx.functional.compose(double, add)
      -- compose(double, add)(3, 4) = double(add(3, 4)) = double(7) = 14
      expect(composed(3, 4)).to.be_equal_to(14)
    end)

    it('should return identity when given a single function', function()
      local function double(x) return x * 2 end
      local composed = llx.functional.compose(double)
      expect(composed(5)).to.be_equal_to(10)
    end)
  end)

  describe('pipe', function()
    it('should compose two functions left-to-right', function()
      local function double(x) return x * 2 end
      local function inc(x) return x + 1 end
      local double_then_inc = llx.functional.pipe(double, inc)
      -- pipe(double, inc)(3) = inc(double(3)) = inc(6) = 7
      expect(double_then_inc(3)).to.be_equal_to(7)
    end)

    it('should compose three functions left-to-right', function()
      local function double(x) return x * 2 end
      local function inc(x) return x + 1 end
      local function negate(x) return -x end
      local piped = llx.functional.pipe(double, inc, negate)
      -- pipe(double, inc, negate)(3) = negate(inc(double(3))) = negate(7) = -7
      expect(piped(3)).to.be_equal_to(-7)
    end)

    it('should pass multiple arguments to the first function', function()
      local function add(a, b) return a + b end
      local function double(x) return x * 2 end
      local piped = llx.functional.pipe(add, double)
      -- pipe(add, double)(3, 4) = double(add(3, 4)) = double(7) = 14
      expect(piped(3, 4)).to.be_equal_to(14)
    end)

    it('should return identity when given a single function', function()
      local function double(x) return x * 2 end
      local piped = llx.functional.pipe(double)
      expect(piped(5)).to.be_equal_to(10)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
