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

    it('should make function assignments in environment '
      .. 'callable via proxy', function()
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

    it('should error when assigning to proxy even after '
      .. 'environment assignment', function()
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
    it('should error when accessing non-existent field '
      .. 'on environment', function()
      local env, proxy = environment.create_module_environment()
      expect(function()
        local _ = env.totally_nonexistent_field_xyz
      end).to.throw()
    end)
  end)

  describe('false-valued module variables', function()
    it('should read back as false from the environment', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      expect(env.flag).to.be_false()
    end)

    it('should read back as false from the proxy', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      expect(proxy.flag).to.be_false()
    end)

    it('should shadow a same-named global rather than falling '
      .. 'through to it', function()
      local env, proxy = environment.create_module_environment()
      -- A global of the same name must not win: the module declared it.
      _G.llx_test_false_shadow = 'the real global'
      env.llx_test_false_shadow = false
      local observed = env.llx_test_false_shadow
      _G.llx_test_false_shadow = nil
      expect(observed).to.be_false()
    end)

    it('should shadow a same-named using_module symbol', function()
      local mod_a = {value = 'from_module'}
      local env, proxy = environment.create_module_environment({mod_a})
      env.value = false
      expect(env.value).to.be_false()
    end)

    it('should not raise when no global of that name exists', function()
      local env, proxy = environment.create_module_environment()
      env.solitary_false_field = false
      expect(function()
        local _ = env.solitary_false_field
      end).to_not.throw()
    end)

    it('should be reported by environment.has', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      expect(environment.has(proxy, 'flag')).to.be_true()
    end)

    it('should appear in pairs iteration over the proxy', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      local collected = {}
      for k, v in pairs(proxy) do collected[k] = v end
      expect(collected.flag).to.be_false()
    end)

    it('should destructure through the proxy __call', function()
      local env, proxy = environment.create_module_environment()
      env.enabled = false
      env.name = 'thing'
      local enabled, name = proxy {'enabled', 'name'}
      expect(enabled).to.be_false()
      expect(name).to.be_equal_to('thing')
    end)

    it('should still raise for a genuinely undefined name', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      expect(function()
        local _ = env.definitely_not_defined_abc
      end).to.throw()
    end)
  end)

  describe('false-valued globals seen through the environment', function()
    it('should read a false global as false, not raise', function()
      local env, proxy = environment.create_module_environment()
      _G.llx_test_false_global = false
      local ok, observed = pcall(function()
        return env.llx_test_false_global
      end)
      _G.llx_test_false_global = nil
      expect(ok).to.be_true()
      expect(observed).to.be_false()
    end)

    it('should read a false using_module symbol as false', function()
      local mod_a = {disabled = false}
      local env, proxy = environment.create_module_environment({mod_a})
      expect(env.disabled).to.be_false()
    end)
  end)

  describe('module code reading its own false state', function()
    -- The regression this guards: a module that keeps boolean state at
    -- module scope used to branch on the value of an unrelated global.
    it('should branch on the module variable, not a same-named '
      .. 'global', function()
      _G.llx_test_verbose = 'I AM THE REAL GLOBAL'
      local chunk = [==[
        local environment = require 'llx.environment'
        local _ENV, _M = environment.create_module_environment()
        llx_test_verbose = false
        function is_on()
          if llx_test_verbose then return 'ON' else return 'OFF' end
        end
        function read() return llx_test_verbose end
        return _M
      ]==]
      local mod = assert(load(chunk, 'false_state_probe'))()
      local is_on, read = mod.is_on(), mod.read()
      _G.llx_test_verbose = nil
      expect(is_on).to.be_equal_to('OFF')
      expect(read).to.be_false()
    end)

    it('should let a module toggle its own boolean state', function()
      local chunk = [==[
        local environment = require 'llx.environment'
        local _ENV, _M = environment.create_module_environment()
        done = false
        function finish() done = true end
        function reset() done = false end
        function is_done() return done end
        return _M
      ]==]
      local mod = assert(load(chunk, 'toggle_probe'))()
      expect(mod.is_done()).to.be_false()
      mod.finish()
      expect(mod.is_done()).to.be_true()
      mod.reset()
      expect(mod.is_done()).to.be_false()
    end)
  end)

  describe('nil-valued module variables are not representable', function()
    -- Pins the contract documented at the top of src/environment.lua: writes
    -- go through rawset, so nil declares nothing. Module state that is
    -- legitimately absent belongs in a module-scope local, not here.
    it('should not declare a name assigned nil', function()
      local env, proxy = environment.create_module_environment()
      env.absent = nil
      expect(environment.has(proxy, 'absent')).to.be_false()
      expect(function()
        local _ = env.absent
      end).to.throw()
    end)

    it('should un-declare a live variable assigned nil', function()
      local env, proxy = environment.create_module_environment()
      env.present = 'here'
      expect(environment.has(proxy, 'present')).to.be_true()
      env.present = nil
      expect(environment.has(proxy, 'present')).to.be_false()
      expect(function()
        local _ = env.present
      end).to.throw()
    end)

    it('should drop an un-declared name from pairs iteration', function()
      local env, proxy = environment.create_module_environment()
      env.kept = 1
      env.dropped = 2
      env.dropped = nil
      local collected = {}
      for k, v in pairs(proxy) do collected[k] = v end
      expect(collected.kept).to.be_equal_to(1)
      expect(collected.dropped).to.be_nil()
    end)

    it('should distinguish nil from false: false stays declared', function()
      local env, proxy = environment.create_module_environment()
      env.flag = false
      expect(environment.has(proxy, 'flag')).to.be_true()
      env.flag = nil
      expect(environment.has(proxy, 'flag')).to.be_false()
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

    it('should allow environment assignments to shadow '
      .. 'using_module symbols', function()
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

  describe('proxy __tostring', function()
    it('should return module<empty> for an empty module', function()
      local _, proxy = environment.create_module_environment()
      expect(tostring(proxy)).to.be_equal_to('module<empty>')
    end)

    it('should list fields when small', function()
      local env, proxy = environment.create_module_environment()
      env.a = 1
      env.b = 2
      local s = tostring(proxy)
      expect(s).to.contain('a')
      expect(s).to.contain('b')
    end)

    it('should truncate and show a count when many fields', function()
      local env, proxy = environment.create_module_environment()
      env.a = 1; env.b = 2; env.c = 3; env.d = 4; env.e = 5
      env.f = 6; env.g = 7
      local s = tostring(proxy)
      expect(s).to.contain('total')
    end)

    it('should hide internal __ fields', function()
      local env, proxy = environment.create_module_environment()
      env.__internal = 'hidden'
      env.visible = 'shown'
      local s = tostring(proxy)
      expect(s).to.contain('visible')
      expect(s).to_not.contain('__internal')
    end)
  end)

  describe('environment.has', function()
    it('should return true for defined fields', function()
      local env, proxy = environment.create_module_environment()
      env.foo = 42
      expect(environment.has(proxy, 'foo')).to.be_true()
    end)

    it('should return false for undefined fields without raising', function()
      local _, proxy = environment.create_module_environment()
      expect(environment.has(proxy, 'never_defined')).to.be_false()
    end)

    it('should return false for non-module tables', function()
      expect(environment.has({a = 1}, 'a')).to.be_false()
    end)
  end)

  describe('environment.deprecated', function()
    it('should call the wrapped function with the original args', function()
      local fn = environment.deprecated('old', function(a, b) return a + b end)
      expect(fn(2, 3)).to.be_equal_to(5)
    end)

    it('should print a warning on first call only', function()
      -- io.stderr is a FILE userdata; substitute a fake stream
      -- table that records writes. Restore after.
      local writes = {}
      local original_stderr = io.stderr
      io.stderr = {
        write = function(self, s) writes[#writes + 1] = s end,
      }
      local ok, err = pcall(function()
        local fn = environment.deprecated('old_fn', function() return 1 end,
                                          'use new_fn')
        fn(); fn(); fn()
      end)
      io.stderr = original_stderr
      if not ok then error(err) end
      expect(#writes).to.be_equal_to(1)
      expect(writes[1]).to.contain('old_fn')
      expect(writes[1]).to.contain('use new_fn')
    end)

    it('should pass through return values unchanged', function()
      local fn = environment.deprecated('old', function(x) return x * 2 end)
      local original_stderr = io.stderr
      io.stderr = {write = function() end}  -- suppress
      local result = fn(21)
      io.stderr = original_stderr
      expect(result).to.be_equal_to(42)
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
  os.exit(unit.run_unit_tests() == 0)
end
