local unit = require 'llx.unit'
local llx = require 'llx'
local class_module = require 'llx.class'
local coroutine_module = require 'llx.coroutine'
local decorator_module = require 'llx.decorator'

local class = class_module.class
local wrap = coroutine_module.wrap
local WrapDecorator = coroutine_module.WrapDecorator
local Decorator = decorator_module.Decorator

_ENV = unit.create_test_env(_ENV)

describe('coroutine', function()
  describe('module exports', function()
    it('should export WrapDecorator class', function()
      expect(WrapDecorator).to_not.be_nil()
    end)

    it('should export wrap instance', function()
      expect(wrap).to_not.be_nil()
    end)

    it('should be accessible via llx.coroutine', function()
      expect(llx.coroutine).to_not.be_nil()
      expect(llx.coroutine.wrap).to_not.be_nil()
    end)
  end)

  describe('WrapDecorator', function()
    it('should be an instance of Decorator', function()
      expect(Decorator:__isinstance(wrap)).to.be_true()
    end)

    it('should have a decorate method', function()
      expect(wrap.decorate).to.be_a('function')
    end)

    it('should return class_table, name, and wrapped function from decorate', function()
      local target = {}
      local fn = function() coroutine.yield(1) end
      local r_target, r_name, r_fn = wrap:decorate(target, 'gen', fn)
      expect(r_target).to.be_equal_to(target)
      expect(r_name).to.be_equal_to('gen')
      expect(type(r_fn)).to.be_equal_to('function')
    end)
  end)

  describe('wrap decorate behavior', function()
    it('should return a coroutine iterator from the wrapped function', function()
      local fn = function()
        coroutine.yield(1)
        coroutine.yield(2)
        coroutine.yield(3)
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      expect(type(iter)).to.be_equal_to('function')
    end)

    it('should yield all values from the coroutine', function()
      local fn = function()
        coroutine.yield(10)
        coroutine.yield(20)
        coroutine.yield(30)
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      local results = {}
      for v in iter do
        results[#results + 1] = v
      end
      expect(#results).to.be_equal_to(3)
      expect(results[1]).to.be_equal_to(10)
      expect(results[2]).to.be_equal_to(20)
      expect(results[3]).to.be_equal_to(30)
    end)

    it('should pass arguments to the underlying function', function()
      local fn = function(start, stop)
        for i = start, stop do
          coroutine.yield(i)
        end
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped(3, 5)
      local results = {}
      for v in iter do
        results[#results + 1] = v
      end
      expect(#results).to.be_equal_to(3)
      expect(results[1]).to.be_equal_to(3)
      expect(results[2]).to.be_equal_to(4)
      expect(results[3]).to.be_equal_to(5)
    end)

    it('should handle a function that yields nothing', function()
      local fn = function()
        -- no yields
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      local count = 0
      for v in iter do
        count = count + 1
      end
      expect(count).to.be_equal_to(0)
    end)

    it('should handle a function that yields a single value', function()
      local fn = function()
        coroutine.yield(42)
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      local result = iter()
      expect(result).to.be_equal_to(42)
      expect(iter()).to.be_nil()
    end)

    it('should create independent iterators on each call', function()
      local fn = function(n)
        for i = 1, n do
          coroutine.yield(i)
        end
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)

      local iter1 = wrapped(3)
      local iter2 = wrapped(2)

      -- Consume iter1 and iter2 independently
      local r1 = {}
      for v in iter1 do r1[#r1 + 1] = v end
      local r2 = {}
      for v in iter2 do r2[#r2 + 1] = v end

      expect(#r1).to.be_equal_to(3)
      expect(#r2).to.be_equal_to(2)
      expect(r1[1]).to.be_equal_to(1)
      expect(r1[3]).to.be_equal_to(3)
      expect(r2[1]).to.be_equal_to(1)
      expect(r2[2]).to.be_equal_to(2)
    end)

    it('should yield string values', function()
      local fn = function()
        coroutine.yield('hello')
        coroutine.yield('world')
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      expect(iter()).to.be_equal_to('hello')
      expect(iter()).to.be_equal_to('world')
      expect(iter()).to.be_nil()
    end)

    it('should yield table values', function()
      local t1 = {1, 2}
      local t2 = {3, 4}
      local fn = function()
        coroutine.yield(t1)
        coroutine.yield(t2)
      end
      local _, _, wrapped = wrap:decorate({}, 'fn', fn)
      local iter = wrapped()
      expect(iter()).to.be_equal_to(t1)
      expect(iter()).to.be_equal_to(t2)
    end)
  end)

  describe('| operator', function()
    it('should be usable with the | operator', function()
      local result = 'my_generator' | wrap
      expect(result.__isdecorator).to.be_true()
      expect(result.name).to.be_equal_to('my_generator')
      expect(#result.decorator_table).to.be_equal_to(1)
    end)
  end)

  describe('class integration', function()
    it('should work as a decorator on class methods', function()
      local MyClass = class 'CoroutineClass' {
        ['range' | wrap] = function(self, n)
          for i = 1, n do
            coroutine.yield(i)
          end
        end,
      }
      local obj = MyClass()
      local results = {}
      for v in obj:range(4) do
        results[#results + 1] = v
      end
      expect(#results).to.be_equal_to(4)
      expect(results[1]).to.be_equal_to(1)
      expect(results[4]).to.be_equal_to(4)
    end)

    it('should work with method that yields computed values', function()
      local MyClass = class 'CoroutineClass2' {
        __init = function(self, factor)
          self.factor = factor
        end,

        ['scaled_range' | wrap] = function(self, n)
          for i = 1, n do
            coroutine.yield(i * self.factor)
          end
        end,
      }
      local obj = MyClass(10)
      local results = {}
      for v in obj:scaled_range(3) do
        results[#results + 1] = v
      end
      expect(#results).to.be_equal_to(3)
      expect(results[1]).to.be_equal_to(10)
      expect(results[2]).to.be_equal_to(20)
      expect(results[3]).to.be_equal_to(30)
    end)

    it('should allow multiple wrapped methods on the same class', function()
      local MyClass = class 'CoroutineClass3' {
        ['evens' | wrap] = function(self, n)
          for i = 2, n, 2 do
            coroutine.yield(i)
          end
        end,

        ['odds' | wrap] = function(self, n)
          for i = 1, n, 2 do
            coroutine.yield(i)
          end
        end,
      }
      local obj = MyClass()
      local even_results = {}
      for v in obj:evens(6) do even_results[#even_results + 1] = v end
      local odd_results = {}
      for v in obj:odds(5) do odd_results[#odd_results + 1] = v end

      expect(#even_results).to.be_equal_to(3)
      expect(even_results[1]).to.be_equal_to(2)
      expect(even_results[2]).to.be_equal_to(4)
      expect(even_results[3]).to.be_equal_to(6)

      expect(#odd_results).to.be_equal_to(3)
      expect(odd_results[1]).to.be_equal_to(1)
      expect(odd_results[2]).to.be_equal_to(3)
      expect(odd_results[3]).to.be_equal_to(5)
    end)

    it('should work with for-in loop pattern', function()
      local MyClass = class 'CoroutineClass4' {
        ['items' | wrap] = function(self)
          coroutine.yield('a')
          coroutine.yield('b')
          coroutine.yield('c')
        end,
      }
      local obj = MyClass()
      local collected = ''
      for v in obj:items() do
        collected = collected .. v
      end
      expect(collected).to.be_equal_to('abc')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
