local unit = require 'llx.unit'
local llx = require 'llx'

local environment = require 'llx.environment'

_ENV = unit.create_test_env(_ENV)

describe('environment', function()
  describe('create_module_environment', function()
    it('should return two values: environment and module proxy', function()
      local env, proxy = environment.create_module_environment()
      expect(env).to_not.be_nil()
      expect(proxy).to_not.be_nil()
      expect(env).to.be_a('table')
      expect(proxy).to.be_a('table')
    end)

    it('should return distinct tables for environment and proxy', function()
      local env, proxy = environment.create_module_environment()
      expect(env).to_not.be_equal_to(proxy)
    end)
  end)

  describe('environment assignments and module visibility', function()
    it('should make assignments in environment visible via proxy', function()
      local env, proxy = environment.create_module_environment()
      env.my_var = 42
      expect(proxy.my_var).to.be_equal_to(42)
    end)

    it('should make function assignments in environment callable via proxy', function()
      local env, proxy = environment.create_module_environment()
      env.add = function(a, b) return a + b end
      expect(proxy.add(10, 20)).to.be_equal_to(30)
    end)

    it('should support multiple assignments', function()
      local env, proxy = environment.create_module_environment()
      env.x = 1
      env.y = 2
      env.z = 3
      expect(proxy.x).to.be_equal_to(1)
      expect(proxy.y).to.be_equal_to(2)
      expect(proxy.z).to.be_equal_to(3)
    end)

    it('should support overwriting values in environment', function()
      local env, proxy = environment.create_module_environment()
      env.value = 'first'
      env.value = 'second'
      expect(proxy.value).to.be_equal_to('second')
    end)

    it('should allow reading back assignments through environment', function()
      local env, proxy = environment.create_module_environment()
      env.foo = 'bar'
      expect(env.foo).to.be_equal_to('bar')
    end)
  end)

  describe('module proxy is read-only', function()
    it('should error when assigning to proxy', function()
      local env, proxy = environment.create_module_environment()
      expect(function()
        proxy.some_field = 'value'
      end).to.throw()
    end)

    it('should error when assigning to proxy even after environment assignment', function()
      local env, proxy = environment.create_module_environment()
      env.existing = 123
      expect(function()
        proxy.existing = 456
      end).to.throw()
    end)
  end)

  describe('proxy __index errors on missing fields', function()
    it('should error when accessing non-existent field on proxy', function()
      local env, proxy = environment.create_module_environment()
      expect(function()
        local _ = proxy.nonexistent
      end).to.throw()
    end)
  end)

  describe('environment __index errors on missing fields', function()
    it('should error when accessing non-existent field on environment', function()
      local env, proxy = environment.create_module_environment()
      expect(function()
        local _ = env.totally_nonexistent_field_xyz
      end).to.throw()
    end)
  end)

  describe('globals are accessible from environment', function()
    it('should provide access to standard library functions', function()
      local env, proxy = environment.create_module_environment()
      expect(env.print).to.be_equal_to(print)
    end)

    it('should provide access to standard library tables', function()
      local env, proxy = environment.create_module_environment()
      expect(env.string).to.be_equal_to(string)
      expect(env.table).to.be_equal_to(table)
      expect(env.math).to.be_equal_to(math)
    end)

    it('should provide access to type function', function()
      local env, proxy = environment.create_module_environment()
      expect(env.type('hello')).to.be_equal_to('string')
    end)
  end)

  describe('using_modules', function()
    it('should merge symbols from a single module', function()
      local mod_a = {foo = 'foo_val', bar = 'bar_val'}
      local env, proxy = environment.create_module_environment({mod_a})
      expect(env.foo).to.be_equal_to('foo_val')
      expect(env.bar).to.be_equal_to('bar_val')
    end)

    it('should merge symbols from multiple modules', function()
      local mod_a = {alpha = 1}
      local mod_b = {beta = 2}
      local env, proxy = environment.create_module_environment({mod_a, mod_b})
      expect(env.alpha).to.be_equal_to(1)
      expect(env.beta).to.be_equal_to(2)
    end)

    it('should not export using_module symbols to the proxy', function()
      local mod_a = {imported_fn = function() return 'imported' end}
      local env, proxy = environment.create_module_environment({mod_a})
      -- The imported symbol is accessible from environment
      expect(env.imported_fn()).to.be_equal_to('imported')
      -- But it should NOT be in the module proxy (not exported)
      expect(function()
        local _ = proxy.imported_fn
      end).to.throw()
    end)

    it('should error on key collision between using modules', function()
      local mod_a = {shared = 'a'}
      local mod_b = {shared = 'b'}
      expect(function()
        environment.create_module_environment({mod_a, mod_b})
      end).to.throw()
    end)

    it('should allow environment assignments to shadow using_module symbols', function()
      local mod_a = {value = 'from_module'}
      local env, proxy = environment.create_module_environment({mod_a})
      -- Before assignment, reads the using_module value
      expect(env.value).to.be_equal_to('from_module')
      -- After assignment, module value takes priority
      env.value = 'from_env'
      expect(env.value).to.be_equal_to('from_env')
      expect(proxy.value).to.be_equal_to('from_env')
    end)
  end)

  describe('proxy __call for destructuring', function()
    it('should destructure single field', function()
      local env, proxy = environment.create_module_environment()
      env.hello = 'world'
      local hello = proxy {'hello'}
      expect(hello).to.be_equal_to('world')
    end)

    it('should destructure multiple fields', function()
      local env, proxy = environment.create_module_environment()
      env.a = 1
      env.b = 2
      env.c = 3
      local a, b, c = proxy {'a', 'b', 'c'}
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)

    it('should error when destructuring a non-existent field', function()
      local env, proxy = environment.create_module_environment()
      expect(function()
        proxy {'nonexistent'}
      end).to.throw()
    end)
  end)

  describe('proxy __pairs iteration', function()
    it('should iterate over all module fields', function()
      local env, proxy = environment.create_module_environment()
      env.x = 10
      env.y = 20
      local collected = {}
      for k, v in pairs(proxy) do
        collected[k] = v
      end
      expect(collected.x).to.be_equal_to(10)
      expect(collected.y).to.be_equal_to(20)
    end)

    it('should reflect only module fields, not using_module symbols', function()
      local mod_a = {imported = 'val'}
      local env, proxy = environment.create_module_environment({mod_a})
      env.exported = 'yes'
      local collected = {}
      for k, v in pairs(proxy) do
        collected[k] = v
      end
      expect(collected.exported).to.be_equal_to('yes')
      -- imported should NOT appear in pairs iteration
      expect(collected.imported).to.be_nil()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
