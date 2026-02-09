local unit = require 'llx.unit'
local llx = require 'llx'
local class_module = require 'llx.class'
local method_module = require 'llx.method'
local type_check_module = require 'llx.type_check_decorator'
local types = require 'llx.types'

-- The type_check_decorator module references isinstance without importing it.
-- It relies on isinstance being available in the global environment (_G), since
-- the module environment's __index falls back to _ENV. We must set it globally
-- before calling any wrapped functions.
isinstance = require 'llx.isinstance' . isinstance

local class = class_module.class
local method = method_module.method
local type_check_decorator = type_check_module.type_check_decorator
local Integer = types.Integer
local Number = types.Number
local String = types.String

_ENV = unit.create_test_env(_ENV)

--- Helper: construct a method-like object that replicates the intended
--- behavior of method.__init and is callable via method.__call.
---
--- This manually performs the same steps as method's __init: it applies
--- decorators in order, then wraps with type_check_decorator. The resulting
--- object delegates to method.__call for invocation.
local function make_method(function_args)
  local underlying_function = function_args[1]
  for _, decorator in ipairs(function_args.decorators or {}) do
    underlying_function = decorator(underlying_function)
  end
  underlying_function = type_check_decorator(underlying_function, function_args.types)
  -- Build a table with the same shape that method.__init would produce,
  -- then use method.__call as its __call metamethod.
  return setmetatable(
    { underlying_function = underlying_function },
    { __call = method.__call }
  )
end

describe('method', function()
  describe('module exports', function()
    it('should export method class', function()
      expect(method).to_not.be_nil()
    end)

    it('should be accessible via llx.method', function()
      expect(llx.method).to_not.be_nil()
      expect(llx.method.method).to_not.be_nil()
    end)

    it('should be a table (class proxy)', function()
      expect(type(method)).to.be_equal_to('table')
    end)
  end)

  describe('method class structure', function()
    it('should have __init defined', function()
      expect(method.__init).to_not.be_nil()
      expect(type(method.__init)).to.be_equal_to('function')
    end)

    it('should have __call defined', function()
      expect(method.__call).to_not.be_nil()
      expect(type(method.__call)).to.be_equal_to('function')
    end)
  end)

  describe('__call invocation', function()
    it('should invoke the underlying function when called', function()
      local m = make_method { function(x) return x * 2 end }
      expect(m(5)).to.be_equal_to(10)
    end)

    it('should pass all arguments to the underlying function', function()
      local m = make_method { function(a, b, c) return a + b + c end }
      expect(m(1, 2, 3)).to.be_equal_to(6)
    end)

    it('should return multiple values', function()
      local m = make_method { function(x) return x, x * 2, x * 3 end }
      local a, b, c = m(5)
      expect(a).to.be_equal_to(5)
      expect(b).to.be_equal_to(10)
      expect(c).to.be_equal_to(15)
    end)

    it('should handle no arguments', function()
      local m = make_method { function() return 42 end }
      expect(m()).to.be_equal_to(42)
    end)

    it('should handle functions returning nil', function()
      local m = make_method { function() return nil end }
      expect(m()).to.be_nil()
    end)

    it('should handle string arguments and return', function()
      local m = make_method { function(s) return s .. '!' end }
      expect(m('hello')).to.be_equal_to('hello!')
    end)

    it('should handle boolean return values', function()
      local m = make_method { function(x) return x > 0 end }
      expect(m(5)).to.be_true()
      expect(m(-1)).to.be_false()
    end)

    it('should handle table return values', function()
      local t = {1, 2, 3}
      local m = make_method { function() return t end }
      expect(m()).to.be_equal_to(t)
    end)
  end)

  describe('decorators', function()
    it('should apply a single decorator', function()
      local function double_result(fn)
        return function(...)
          return fn(...) * 2
        end
      end

      local m = make_method {
        function(x) return x end,
        decorators = { double_result },
      }
      expect(m(5)).to.be_equal_to(10)
    end)

    it('should apply multiple decorators in order', function()
      local function add_one(fn)
        return function(...)
          return fn(...) + 1
        end
      end

      local function double_result(fn)
        return function(...)
          return fn(...) * 2
        end
      end

      -- Decorators are applied in iteration order:
      -- 1. add_one wraps the base function: add_one(fn)(3) => fn(3) + 1 = 4
      -- 2. double_result wraps that: double_result(add_one(fn))(3) => 4 * 2 = 8
      local m = make_method {
        function(x) return x end,
        decorators = { add_one, double_result },
      }
      expect(m(3)).to.be_equal_to(8)
    end)

    it('should apply decorators so that last decorator is outermost', function()
      local order = {}

      local function first_decorator(fn)
        return function(...)
          order[#order + 1] = 'first'
          return fn(...)
        end
      end

      local function second_decorator(fn)
        return function(...)
          order[#order + 1] = 'second'
          return fn(...)
        end
      end

      local m = make_method {
        function() return 'done' end,
        decorators = { first_decorator, second_decorator },
      }
      m()
      -- second_decorator wraps first_decorator, so second runs first
      expect(#order).to.be_equal_to(2)
      expect(order[1]).to.be_equal_to('second')
      expect(order[2]).to.be_equal_to('first')
    end)

    it('should work with a logging decorator', function()
      local log = {}
      local function logging_decorator(fn)
        return function(...)
          log[#log + 1] = 'called'
          return fn(...)
        end
      end

      local m = make_method {
        function(x) return x * x end,
        decorators = { logging_decorator },
      }
      expect(m(4)).to.be_equal_to(16)
      expect(m(5)).to.be_equal_to(25)
      expect(#log).to.be_equal_to(2)
    end)

    it('should work with no decorators specified', function()
      local m = make_method {
        function(x) return x + 1 end,
      }
      expect(m(10)).to.be_equal_to(11)
    end)

    it('should work with empty decorators list', function()
      local m = make_method {
        function(x) return x + 1 end,
        decorators = {},
      }
      expect(m(10)).to.be_equal_to(11)
    end)

    it('should chain three decorators correctly', function()
      local function add_one(fn)
        return function(...) return fn(...) + 1 end
      end
      local function double(fn)
        return function(...) return fn(...) * 2 end
      end
      local function negate(fn)
        return function(...) return -fn(...) end
      end

      -- Applied in order: negate(double(add_one(fn)))
      -- fn(5) = 5; add_one => 6; double => 12; negate => -12
      local m = make_method {
        function(x) return x end,
        decorators = { add_one, double, negate },
      }
      expect(m(5)).to.be_equal_to(-12)
    end)
  end)

  describe('type checking', function()
    it('should pass when argument type matches Integer', function()
      local m = make_method {
        function(x) return x + 1 end,
        types = { args = { Integer } },
      }
      expect(m(5)).to.be_equal_to(6)
    end)

    it('should pass with multiple correct argument types', function()
      local m = make_method {
        function(a, b) return a .. b end,
        types = { args = { String, String } },
      }
      expect(m('hello', ' world')).to.be_equal_to('hello world')
    end)

    it('should throw when argument type does not match', function()
      local m = make_method {
        function(x) return x + 1 end,
        types = { args = { Integer } },
      }
      expect(function() m('not a number') end).to.throw()
    end)

    it('should not type-check when types is nil', function()
      local m = make_method {
        function(x) return tostring(x) end,
      }
      -- Should accept any type without error
      expect(m(42)).to.be_equal_to('42')
      expect(m('hello')).to.be_equal_to('hello')
      expect(m(true)).to.be_equal_to('true')
    end)

    it('should check return types when specified', function()
      local m = make_method {
        function(x) return x end,
        types = { returns = { Number } },
      }
      expect(m(5)).to.be_equal_to(5)
    end)

    it('should throw when return type does not match', function()
      local m = make_method {
        function(x) return x end,
        types = { returns = { Integer } },
      }
      expect(function() m('hello') end).to.throw()
    end)

    it('should check both argument and return types', function()
      local m = make_method {
        function(x) return x * 2 end,
        types = { args = { Integer }, returns = { Integer } },
      }
      expect(m(5)).to.be_equal_to(10)
    end)

    it('should throw for wrong arg type even when return type is specified', function()
      local m = make_method {
        function(x) return x end,
        types = { args = { Integer }, returns = { Integer } },
      }
      expect(function() m('hello') end).to.throw()
    end)
  end)

  describe('decorators combined with type checking', function()
    it('should apply decorators before type checking wraps them', function()
      local decorated = false
      local function my_decorator(fn)
        return function(...)
          decorated = true
          return fn(...)
        end
      end

      local m = make_method {
        function(x) return x * 2 end,
        decorators = { my_decorator },
        types = { args = { Integer } },
      }
      expect(m(3)).to.be_equal_to(6)
      expect(decorated).to.be_true()
    end)

    it('should type-check after decorators are applied', function()
      local function identity_decorator(fn)
        return fn
      end

      local m = make_method {
        function(x) return x end,
        decorators = { identity_decorator },
        types = { args = { String } },
      }
      expect(m('hello')).to.be_equal_to('hello')
      expect(function() m(123) end).to.throw()
    end)
  end)

  describe('usage in class definitions', function()
    it('should allow method instances to be stored in class fields', function()
      local m = make_method { function(name) return 'Hello, ' .. name end }
      local MyClass = class 'MethodClass' {
        greet = m,
      }
      expect(MyClass.greet('World')).to.be_equal_to('Hello, World')
    end)

    it('should work as an instance method via class field', function()
      local m = make_method { function(self, x) return x * self.multiplier end }
      local MyClass = class 'MethodClass2' {
        __init = function(self, multiplier)
          self.multiplier = multiplier
        end,
        scale = m,
      }
      local obj = MyClass(3)
      expect(obj:scale(5)).to.be_equal_to(15)
    end)

    it('should be callable as a standalone method object', function()
      local m = make_method { function(a, b) return a + b end }
      expect(m(10, 20)).to.be_equal_to(30)
    end)
  end)

  describe('__call metamethod directly', function()
    it('should forward arguments to underlying_function', function()
      local called_with = {}
      local obj = { underlying_function = function(...)
        called_with = {...}
        return 'result'
      end }
      local result = method.__call(obj, 'a', 'b', 'c')
      expect(result).to.be_equal_to('result')
      expect(#called_with).to.be_equal_to(3)
      expect(called_with[1]).to.be_equal_to('a')
      expect(called_with[2]).to.be_equal_to('b')
      expect(called_with[3]).to.be_equal_to('c')
    end)

    it('should return the value from underlying_function', function()
      local obj = { underlying_function = function() return 99 end }
      expect(method.__call(obj, nil)).to.be_equal_to(99)
    end)

    it('should return multiple values from underlying_function', function()
      local obj = { underlying_function = function() return 1, 2, 3 end }
      local a, b, c = method.__call(obj)
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
