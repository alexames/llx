-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.functional'

_ENV = unit.create_test_env(_ENV)

describe('functional combinators (tier 3)', function()
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
