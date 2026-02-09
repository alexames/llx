local unit = require 'llx.unit'
local llx = require 'llx'
local class_module = require 'llx.class'
local cache_module = require 'llx.cache'
local decorator_module = require 'llx.decorator'

local class = class_module.class
local cache = cache_module.cache
local Decorator = decorator_module.Decorator

_ENV = unit.create_test_env(_ENV)

describe('Cache', function()
  describe('module exports', function()
    it('should export cache instance', function()
      expect(cache).to_not.be_nil()
    end)

    it('should be an instance of Decorator', function()
      expect(Decorator:__isinstance(cache)).to.be_true()
    end)
  end)

  describe('cache instance', function()
    it('should have a decorate method', function()
      expect(cache.decorate).to.be_a('function')
    end)
  end)

  describe('memoization via decorate', function()
    it('should return a wrapped function from decorate', function()
      local target = {}
      local fn = function(x) return x * 2 end
      local r_target, r_name, r_fn = cache:decorate(target, 'my_fn', fn)
      expect(r_target).to.be_equal_to(target)
      expect(r_name).to.be_equal_to('my_fn')
      expect(type(r_fn)).to.be_equal_to('function')
    end)

    it('should return the correct result for a single call', function()
      local fn = function(x) return x * 2 end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)
      expect(wrapped(5)).to.be_equal_to(10)
    end)

    it('should cache the result for same arguments', function()
      local call_count = 0
      local fn = function(x)
        call_count = call_count + 1
        return x * 2
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      local result1 = wrapped(5)
      local result2 = wrapped(5)
      expect(result1).to.be_equal_to(10)
      expect(result2).to.be_equal_to(10)
      expect(call_count).to.be_equal_to(1)
    end)

    it('should compute separately for different arguments', function()
      local call_count = 0
      local fn = function(x)
        call_count = call_count + 1
        return x * 2
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      local result1 = wrapped(5)
      local result2 = wrapped(10)
      expect(result1).to.be_equal_to(10)
      expect(result2).to.be_equal_to(20)
      expect(call_count).to.be_equal_to(2)
    end)

    it('should cache results for multiple argument sets independently', function()
      local call_count = 0
      local fn = function(a, b)
        call_count = call_count + 1
        return a + b
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      expect(wrapped(1, 2)).to.be_equal_to(3)
      expect(wrapped(3, 4)).to.be_equal_to(7)
      expect(wrapped(1, 2)).to.be_equal_to(3)
      expect(wrapped(3, 4)).to.be_equal_to(7)
      expect(call_count).to.be_equal_to(2)
    end)

    it('should handle zero-argument functions', function()
      local call_count = 0
      local fn = function()
        call_count = call_count + 1
        return 42
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      expect(wrapped()).to.be_equal_to(42)
      expect(wrapped()).to.be_equal_to(42)
      expect(call_count).to.be_equal_to(1)
    end)

    it('should handle string arguments', function()
      local call_count = 0
      local fn = function(s)
        call_count = call_count + 1
        return s .. '!'
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      expect(wrapped('hello')).to.be_equal_to('hello!')
      expect(wrapped('hello')).to.be_equal_to('hello!')
      expect(wrapped('world')).to.be_equal_to('world!')
      expect(call_count).to.be_equal_to(2)
    end)

    it('should distinguish between different argument types', function()
      local call_count = 0
      local fn = function(x)
        call_count = call_count + 1
        return tostring(x)
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      -- 1 (number) vs "1" (string) should be different keys
      wrapped(1)
      wrapped('1')
      expect(call_count).to.be_equal_to(2)
    end)

    it('should handle functions returning nil', function()
      local call_count = 0
      local fn = function()
        call_count = call_count + 1
        return nil
      end
      local _, _, wrapped = cache:decorate({}, 'fn', fn)

      -- nil return is wrapped in {value=nil}, so first call computes
      local result = wrapped(1)
      expect(result).to.be_nil()
      -- Second call should use cache (result.value is nil but entry exists)
      local result2 = wrapped(1)
      expect(result2).to.be_nil()
      -- Due to how cache works: result = {value = nil}, cache[key] = result
      -- On second call: result = cache[key] => {value=nil} which is not nil
      -- so it returns result.value => nil without calling fn again
      expect(call_count).to.be_equal_to(1)
    end)
  end)

  describe('decorator integration with class', function()
    it('should work as a decorator on class methods', function()
      local call_count = 0
      local MyClass = class 'CachedClass' {
        ['compute' | cache] = function(self, x)
          call_count = call_count + 1
          return x * x
        end,
      }
      local obj = MyClass()
      expect(obj:compute(3)).to.be_equal_to(9)
      expect(obj:compute(3)).to.be_equal_to(9)
      expect(call_count).to.be_equal_to(1)
    end)

    it('should compute separately for different args in class methods', function()
      local call_count = 0
      local MyClass = class 'CachedClass2' {
        ['compute' | cache] = function(self, x)
          call_count = call_count + 1
          return x * x
        end,
      }
      local obj = MyClass()
      expect(obj:compute(3)).to.be_equal_to(9)
      expect(obj:compute(4)).to.be_equal_to(16)
      expect(call_count).to.be_equal_to(2)
    end)

    it('should share cache across instances of the same class', function()
      local call_count = 0
      local MyClass = class 'CachedClass3' {
        ['compute' | cache] = function(self, x)
          call_count = call_count + 1
          return x + 1
        end,
      }
      local obj1 = MyClass()
      local obj2 = MyClass()
      -- The cache is per-function (shared across all instances via the class
      -- method). Since both instances are empty tables, they hash identically,
      -- so the cache treats obj1:compute(5) and obj2:compute(5) as the same key.
      expect(obj1:compute(5)).to.be_equal_to(6)
      expect(obj2:compute(5)).to.be_equal_to(6)
      expect(obj1:compute(5)).to.be_equal_to(6)
      expect(obj2:compute(5)).to.be_equal_to(6)
      expect(call_count).to.be_equal_to(1)
    end)

    it('should be usable with the | operator', function()
      local result = 'my_func' | cache
      expect(result.__isdecorator).to.be_true()
      expect(result.name).to.be_equal_to('my_func')
      expect(#result.decorator_table).to.be_equal_to(1)
    end)
  end)

  describe('recursive fibonacci memoization', function()
    it('should correctly compute fibonacci with cache', function()
      local call_count = 0
      local Fibonacci = class 'Fibonacci' {
        ['fib' | cache] = function(self, i)
          call_count = call_count + 1
          if i <= 1 then
            return i
          else
            return self:fib(i - 1) + self:fib(i - 2)
          end
        end,
      }
      local f = Fibonacci()
      expect(f:fib(0)).to.be_equal_to(0)
      expect(f:fib(1)).to.be_equal_to(1)
      expect(f:fib(10)).to.be_equal_to(55)
    end)

    it('should reduce call count due to memoization', function()
      local call_count = 0
      local Fibonacci = class 'Fibonacci2' {
        ['fib' | cache] = function(self, i)
          call_count = call_count + 1
          if i <= 1 then
            return i
          else
            return self:fib(i - 1) + self:fib(i - 2)
          end
        end,
      }
      local f = Fibonacci()
      f:fib(10)
      -- Without cache, fib(10) would require 177 calls.
      -- With cache, it should be at most 11 calls (fib(0) through fib(10)).
      expect(call_count).to.be_less_than_or_equal(11)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
