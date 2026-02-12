-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.operators'
require 'llx.functional'
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
      -- compose(negate, inc, double)(3)
      --   = negate(inc(double(3)))
      --   = negate(inc(6)) = negate(7) = -7
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
      local add3 = llx.functional.curry(
        function(a, b, c) return a + b + c end, 3)
      expect(add3(1)(2)(3)).to.be_equal_to(6)
    end)

    it('should allow partial application with multiple args', function()
      local add3 = llx.functional.curry(
        function(a, b, c) return a + b + c end, 3)
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

  describe('juxt', function()
    it('should apply multiple functions to the same arguments', function()
      local stats = llx.functional.juxt(math.min, math.max)
      local result = stats(3, 1, 4, 1, 5)
      expect(result[1]).to.be_equal_to(1)
      expect(result[2]).to.be_equal_to(5)
    end)

    it('should work with a single function', function()
      local f = llx.functional.juxt(function(x) return x * 2 end)
      local result = f(5)
      expect(result[1]).to.be_equal_to(10)
    end)

    it('should return a List', function()
      local f = llx.functional.juxt(
        function(x) return x + 1 end,
        function(x) return x - 1 end
      )
      local result = f(10)
      expect(#result).to.be_equal_to(2)
      expect(result[1]).to.be_equal_to(11)
      expect(result[2]).to.be_equal_to(9)
    end)
  end)

  describe('wrap', function()
    it('should pass the original function to the wrapper', function()
      local double = function(x) return x * 2 end
      local wrapped = llx.functional.wrap(double, function(fn, x)
        return fn(x) + 1
      end)
      expect(wrapped(5)).to.be_equal_to(11)
    end)

    it('should pass extra arguments to the wrapper', function()
      local greet = function(name) return "hello " .. name end
      local wrapped = llx.functional.wrap(greet, function(fn, name, exclaim)
        local result = fn(name)
        if exclaim then result = result .. "!" end
        return result
      end)
      expect(wrapped("world", true)).to.be_equal_to("hello world!")
      expect(wrapped("world", false)).to.be_equal_to("hello world")
    end)
  end)

  describe('partial_right', function()
    it('should pre-fill arguments from the right', function()
      local div = function(a, b) return a / b end
      local half = llx.functional.partial_right(div, 2)
      expect(half(10)).to.be_equal_to(5)
    end)

    it('should append bound args after call-time args', function()
      local f = function(a, b, c) return a .. b .. c end
      local g = llx.functional.partial_right(f, "c")
      expect(g("a", "b")).to.be_equal_to("abc")
    end)

    it('should handle multiple bound args', function()
      local f = function(a, b, c) return a + b + c end
      local g = llx.functional.partial_right(f, 2, 3)
      expect(g(1)).to.be_equal_to(6)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
