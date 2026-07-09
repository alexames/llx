local unit = require 'llx.unit'
local llx = require 'llx'

local signature_module = require 'llx.signature'
local class_module = require 'llx.class'
local decorator_module = require 'llx.decorator'
local types = require 'llx.types'
local isinstance = require 'llx.isinstance' . isinstance

local Signature = signature_module.Signature
local class = class_module.class
local Decorator = decorator_module.Decorator
local Integer = types.Integer
local Number = types.Number
local String = types.String

_ENV = unit.create_test_env(_ENV)

describe('Signature', function()
  describe('module exports', function()
    it('should export Signature', function()
      expect(Signature).to_not.be_nil()
    end)

    it('should not pollute stdout on require', function()
      -- Require llx.signature in a fresh subprocess and check that
      -- it produces no output. Regression for top-level test code
      -- that previously ran on every import.
      local cmd = 'lua5.4 -e "require \'llx.signature\'" 2>&1'
      local handle = io.popen(cmd)
      if handle then
        local output = handle:read('*a')
        handle:close()
        expect(output).to.be_equal_to('')
      end
    end)
  end)

  describe('Signature class', function()
    it('should be an instance of Decorator', function()
      local sig = Signature{params={}, returns={}}
      expect(isinstance(sig, Decorator)).to.be_true()
    end)

    it('should store params in the instance', function()
      local sig = Signature{params={Integer, Integer}, returns={}}
      expect(sig.params[1]).to.be_equal_to(Integer)
      expect(sig.params[2]).to.be_equal_to(Integer)
    end)

    it('should store returns in the instance', function()
      local sig = Signature{params={}, returns={Integer, String}}
      expect(sig.returns[1]).to.be_equal_to(Integer)
      expect(sig.returns[2]).to.be_equal_to(String)
    end)
  end)

  describe('Signature decorate method', function()
    it('should wrap a function value into a Function object', function()
      local sig = Signature{params={}, returns={}}
      local target = {}
      local name = 'my_func'
      local value = function() end
      local r_target, r_name, r_value = sig:decorate(target, name, value)
      expect(r_target).to.be_equal_to(target)
      expect(r_name).to.be_equal_to(name)
      -- r_value should be a Function object (a table), not the raw function
      expect(type(r_value)).to.be_equal_to('table')
    end)

    it('should create a Function with the correct params', function()
      local sig = Signature{params={Integer, Integer}, returns={}}
      local target = {}
      local _, _, wrapped = sig:decorate(target, 'f', function() end)
      expect(wrapped.params[1]).to.be_equal_to(Integer)
      expect(wrapped.params[2]).to.be_equal_to(Integer)
    end)

    it('should create a Function with the correct returns', function()
      local sig = Signature{params={}, returns={String}}
      local target = {}
      local _, _, wrapped = sig:decorate(
        target, 'f', function() return 'hi' end)
      expect(wrapped.returns[1]).to.be_equal_to(String)
    end)

    it('should create a Function that holds the original '
      .. 'function in func', function()
      local original = function() return 42 end
      local sig = Signature{params={}, returns={Integer}}
      local _, _, wrapped = sig:decorate({}, 'f', original)
      expect(wrapped.func).to.be_equal_to(original)
    end)
  end)

  describe('Function __call (precondition and postcondition '
    .. 'checking)', function()
    it('should call the underlying function and return its result', function()
      local MyClass = class 'SigTestCallClass' {
        ['compute' | Signature{params={'SigTestCallClass', Integer, Integer},
                                returns={Integer}}] =
        function(self, a, b)
          return a + b
        end,
      }
      local obj = MyClass()
      local result = obj:compute(10, 20)
      expect(result).to.be_equal_to(30)
    end)

    it('should pass when all argument types are correct', function()
      local MyClass = class 'SigTestPassClass' {
        ['sum' | Signature{
            params={'SigTestPassClass',
                    Integer, Integer, Integer},
            returns={Integer}}] =
        function(self, a, b, c)
          return a + b + c
        end,
      }
      local obj = MyClass()
      local success, result = pcall(function() return obj:sum(1, 2, 3) end)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(6)
    end)

    it('should error when an argument type is wrong '
      .. '(precondition fail)', function()
      local MyClass = class 'SigTestPreClass' {
        ['add' | Signature{params={'SigTestPreClass', Integer, Integer},
                            returns={Integer}}] =
        function(self, a, b)
          return a + b
        end,
      }
      local obj = MyClass()
      local success = pcall(function() obj:add('not_an_int', 2) end)
      expect(success).to.be_false()
    end)

    it('should error when the return type is wrong '
      .. '(postcondition fail)', function()
      local MyClass = class 'SigTestPostClass' {
        ['bad_return' | Signature{params={'SigTestPostClass'},
                                   returns={Integer}}] =
        function(self)
          return 'this is a string'
        end,
      }
      local obj = MyClass()
      local success = pcall(function() obj:bad_return() end)
      expect(success).to.be_false()
    end)

    it('should pass a method with only self declared and no '
      .. 'returns', function()
      local MyClass = class 'SigTestEmptyClass' {
        ['noop' | Signature{params={'SigTestEmptyClass'}, returns={}}] =
        function(self)
          -- do nothing
        end,
      }
      local obj = MyClass()
      local success = pcall(function() obj:noop() end)
      expect(success).to.be_true()
    end)

    it('should pass with empty params and returns', function()
      local sig = Signature{params={}, returns={}}
      local _, _, wrapped = sig:decorate({}, 'f', function() end)
      local success = pcall(function() wrapped() end)
      expect(success).to.be_true()
    end)

    it('should check multiple return values', function()
      local MyClass = class 'SigTestMultiRetClass' {
        ['get_pair' | Signature{params={'SigTestMultiRetClass'},
                                 returns={Integer, String}}] =
        function(self)
          return 42, 'hello'
        end,
      }
      local obj = MyClass()
      local a, b = obj:get_pair()
      expect(a).to.be_equal_to(42)
      expect(b).to.be_equal_to('hello')
    end)

    it('should error when second return value has wrong type', function()
      local MyClass = class 'SigTestBadMultiRetClass' {
        ['get_pair' | Signature{params={'SigTestBadMultiRetClass'},
                                 returns={Integer, String}}] =
        function(self)
          return 42, 99  -- second should be String
        end,
      }
      local obj = MyClass()
      local success = pcall(function() obj:get_pair() end)
      expect(success).to.be_false()
    end)
  end)

  describe('Function metadata', function()
    it('should expose params on the decorated function', function()
      local MyClass = class 'SigTestParamsClass' {
        ['f' | Signature{params={Integer}, returns={Integer}}] =
        function(self)
          return 1
        end,
      }
      local obj = MyClass()
      expect(type(obj.f.params)).to.be_equal_to('table')
      expect(obj.f.params[1]).to.be_equal_to(Integer)
    end)

    it('should expose returns on the decorated function', function()
      local MyClass = class 'SigTestReturnsClass' {
        ['f' | Signature{params={}, returns={String, Integer}}] =
        function(self)
          return 'hi', 1
        end,
      }
      local obj = MyClass()
      expect(type(obj.f.returns)).to.be_equal_to('table')
      expect(obj.f.returns[1]).to.be_equal_to(String)
      expect(obj.f.returns[2]).to.be_equal_to(Integer)
    end)

    it('should expose the original function as func', function()
      local original = function(self) return 1 end
      local MyClass = class 'SigTestFuncClass' {
        ['f' | Signature{params={}, returns={Integer}}] = original,
      }
      local obj = MyClass()
      expect(obj.f.func).to.be_equal_to(original)
    end)

    it('should have a tostring representation', function()
      local MyClass = class 'SigTestTostringClass' {
        ['f' | Signature{params={Integer, String}, returns={Integer}}] =
        function(self)
          return 1
        end,
      }
      local obj = MyClass()
      local str = tostring(obj.f)
      expect(type(str)).to.be_equal_to('string')
      expect(str:find('Function')).to_not.be_nil()
      expect(str:find('params')).to_not.be_nil()
      expect(str:find('returns')).to_not.be_nil()
    end)
  end)

  describe('Function __call arity enforcement', function()
    local function make_wrapped(params, returns, func)
      local sig = Signature{params=params, returns=returns}
      local _, _, wrapped = sig:decorate({}, 'f', func)
      return wrapped
    end

    it('should pass a call with exactly the declared count', function()
      local wrapped = make_wrapped(
        {Integer}, {Integer}, function(n) return n + 1 end)
      local success, result = pcall(function() return wrapped(1) end)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(2)
    end)

    it('should error on a call with extra arguments', function()
      local wrapped = make_wrapped(
        {Integer}, {Integer}, function(n) return n end)
      local success = pcall(function() wrapped(1, 'surprise', {}) end)
      expect(success).to.be_false()
    end)

    it('should report the offending index and counts', function()
      local wrapped = make_wrapped(
        {Integer}, {Integer}, function(n) return n end)
      local success, err = pcall(function() wrapped(1, 2) end)
      expect(success).to.be_false()
      expect(err.what:find('bad argument #2', 1, true)).to_not.be_nil()
      expect(err.what:find('expected at most 1 value(s), got 2', 1, true))
        .to_not.be_nil()
    end)

    it('should count embedded nil arguments as extra', function()
      -- #-based counting would see one argument here; select('#')
      -- style counting sees three.
      local wrapped = make_wrapped(
        {Integer}, {Integer}, function(n) return n end)
      local success = pcall(function() wrapped(1, nil, nil) end)
      expect(success).to.be_false()
    end)

    it('should error on extra arguments to a signature-annotated '
      .. 'method', function()
      local MyClass = class 'SigTestArityClass' {
        ['add' | Signature{params={'SigTestArityClass', Integer, Integer},
                            returns={Integer}}] =
        function(self, a, b)
          return a + b
        end,
      }
      local obj = MyClass()
      local success = pcall(function() obj:add(1, 2, 3) end)
      expect(success).to.be_false()
    end)

    it('should error when extra return values are produced', function()
      local wrapped = make_wrapped(
        {}, {Integer}, function() return 1, 'extra' end)
      local success = pcall(function() wrapped() end)
      expect(success).to.be_false()
    end)

    it('should not treat missing optional trailing arguments as an '
      .. 'arity error', function()
      local Optional = require 'llx.types.matchers' . Optional
      local wrapped = make_wrapped(
        {Integer, Optional(Integer)}, {Integer},
        function(a, b) return a + (b or 0) end)
      local success, result = pcall(function() return wrapped(4) end)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(4)
    end)

    it('should preserve declared nil return values', function()
      local Optional = require 'llx.types.matchers' . Optional
      local wrapped = make_wrapped(
        {}, {Optional(Integer), Integer}, function() return nil, 5 end)
      local a, b = wrapped()
      expect(a).to.be_nil()
      expect(b).to.be_equal_to(5)
    end)

    it('should accept plain list tables when the check methods are '
      .. 'called directly', function()
      local wrapped = make_wrapped(
        {Integer}, {Integer}, function(n) return n end)
      local ok = pcall(function() wrapped:check_preconditions({1}) end)
      expect(ok).to.be_true()
      local overfull =
        pcall(function() wrapped:check_preconditions({1, 2}) end)
      expect(overfull).to.be_false()
    end)

    it('should allow extra arguments with a trailing "..." in '
      .. 'params', function()
      local wrapped = make_wrapped(
        {Integer, '...'}, {Integer}, function(n) return n end)
      local success, result =
        pcall(function() return wrapped(7, 'x', {}, false) end)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(7)
    end)

    it('should still type-check the fixed prefix of a variadic '
      .. 'signature', function()
      local wrapped = make_wrapped(
        {Integer, '...'}, {Integer}, function(n) return 1 end)
      local success = pcall(function() wrapped('not_an_int', 'x') end)
      expect(success).to.be_false()
    end)

    it('should allow extra return values with a trailing "..." in '
      .. 'returns', function()
      local wrapped = make_wrapped(
        {}, {Integer, '...'}, function() return 1, 'extra', {} end)
      local success, a, b = pcall(function() return wrapped() end)
      expect(success).to.be_true()
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to('extra')
    end)
  end)

  describe('type system integration', function()
    it('should make wrapped functions pass isinstance checks '
      .. 'for types.Function', function()
      local sig = Signature{params={Integer}, returns={String}}
      local _, _, wrapped = sig:decorate(
        {}, 'f', function(n) return tostring(n) end)
      expect(type(wrapped)).to.be_equal_to('table')
      expect(isinstance(wrapped, types.Function)).to.be_true()
    end)

    it('should let Protocol accept an object with a '
      .. 'signature-annotated method', function()
      local matchers = require 'llx.types.matchers'
      local MyClass = class 'SigTestProtocolClass' {
        ['on_tick' | Signature{
            params={'SigTestProtocolClass', Integer},
            returns={}}] =
        function(self, n) end,
      }
      local obj = MyClass()
      local Ticker = matchers.Protocol{on_tick = types.Function}
      expect(isinstance(obj, Ticker)).to.be_true()
    end)
  end)

end)

if llx.main_file() then
  unit.run_unit_tests()
end
