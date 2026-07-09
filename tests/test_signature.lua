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

  describe('TypeVar generic signatures', function()
    local matchers = require 'llx.types.matchers'
    local TypeVar = matchers.TypeVar
    local ListOf = matchers.ListOf
    local Dict = matchers.Dict
    local Overload = signature_module.Overload

    local function make_wrapped(params, returns, func)
      return Signature{params=params, returns=returns} .. func
    end

    it('should bind a TypeVar to the argument and accept a '
      .. 'consistent return', function()
      local T = TypeVar('T')
      local identity = make_wrapped({T}, {T}, function(x) return x end)
      expect(identity(42)).to.be_equal_to(42)
      -- The binding is per call: a fresh call re-binds from scratch.
      expect(identity('hi')).to.be_equal_to('hi')
    end)

    it('should reject a return value inconsistent with the '
      .. 'parameter binding', function()
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {T}, {T}, function(x) return 'oops' end)
      expect(pcall(wrapped, 1)).to.be_false()
      expect(wrapped('oops')).to.be_equal_to('oops')
    end)

    it('should accept two values of the same type for '
      .. 'params={T, T}', function()
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {T, T}, {}, function(a, b) end)
      expect(pcall(wrapped, 1, 2)).to.be_true()
      expect(pcall(wrapped, 'a', 'b')).to.be_true()
    end)

    it('should reject mixed types for params={T, T}', function()
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {T, T}, {}, function(a, b) end)
      expect(pcall(wrapped, 1, 'x')).to.be_false()
      -- Numbers bind narrowly: an Integer witness rejects a Float.
      expect(pcall(wrapped, 1, 1.5)).to.be_false()
    end)

    it('should accept a subclass instance after a superclass '
      .. 'binding, but not the reverse', function()
      local Animal = class 'SigTypeVarAnimal' { }
      local Cat = class 'SigTypeVarCat' : extends(Animal) { }
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {T, T}, {}, function(a, b) end)
      expect(pcall(wrapped, Animal(), Cat())).to.be_true()
      expect(pcall(wrapped, Cat(), Animal())).to.be_false()
    end)

    it('should reject values outside a declared bound', function()
      local N = TypeVar('N', {bound=Number})
      local wrapped = make_wrapped(
        {N}, {N}, function(x) return x end)
      expect(wrapped(2)).to.be_equal_to(2)
      expect(pcall(wrapped, 'not a number')).to.be_false()
    end)

    it('should propagate bindings through ListOf into the return',
        function()
      local T = TypeVar('T')
      local first = make_wrapped(
        {ListOf(T)}, {T}, function(xs) return xs[1] end)
      expect(first({1, 2, 3})).to.be_equal_to(1)
      expect(first({'a', 'b'})).to.be_equal_to('a')
      -- A mixed-element list can satisfy no single binding.
      expect(pcall(first, {1, 'x'})).to.be_false()
    end)

    it('should reject a return inconsistent with a binding '
      .. 'inferred inside ListOf', function()
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {ListOf(T)}, {T}, function(xs) return 'nope' end)
      expect(pcall(wrapped, {1, 2})).to.be_false()
    end)

    it('should bind Dict key and value variables independently',
        function()
      local K = TypeVar('K')
      local V = TypeVar('V')
      local lookup = make_wrapped(
        {Dict(K, V), K}, {V}, function(d, k) return d[k] end)
      expect(lookup({a=1, b=2}, 'a')).to.be_equal_to(1)
      -- The key argument must be consistent with the key binding.
      expect(pcall(lookup, {a=1, b=2}, 5)).to.be_false()
    end)

    it('should leave no active binding scope after a failed call',
        function()
      local T = TypeVar('T')
      local wrapped = make_wrapped(
        {T, T}, {}, function(a, b) end)
      expect(pcall(wrapped, 1, 'x')).to.be_false()
      -- The scope was exited on failure: plain isinstance is back to
      -- the unbound behavior, and a later call re-binds from scratch.
      expect(isinstance('anything', T)).to.be_true()
      expect(pcall(wrapped, 'a', 'b')).to.be_true()
    end)

    it('should keep bindings isolated across recursive calls',
        function()
      local T = TypeVar('T')
      local echo
      echo = make_wrapped({T}, {T}, function(x)
        if x == 3 then
          -- The inner activation binds T to String while the outer
          -- call's Integer binding is suspended; both must succeed.
          expect(echo('inner')).to.be_equal_to('inner')
        end
        return x
      end)
      expect(echo(3)).to.be_equal_to(3)
    end)

    it('should keep bindings isolated across coroutines', function()
      local T = TypeVar('T')
      local wrapped = make_wrapped({T}, {T}, function(x)
        coroutine.yield()
        return x
      end)
      -- Each coroutine suspends inside the wrapped function's body,
      -- between its argument check and its return check; the two
      -- calls' bindings must not interfere.
      local co1 = coroutine.create(function() return wrapped(1) end)
      local co2 = coroutine.create(function() return wrapped('s') end)
      expect(coroutine.resume(co1)).to.be_true()
      expect(coroutine.resume(co2)).to.be_true()
      local ok1, r1 = coroutine.resume(co1)
      local ok2, r2 = coroutine.resume(co2)
      expect(ok1).to.be_true()
      expect(r1).to.be_equal_to(1)
      expect(ok2).to.be_true()
      expect(r2).to.be_equal_to('s')
    end)

    it('should dispatch overloads with generic candidates and keep '
      .. 'candidate scopes isolated', function()
      local T = TypeVar('T')
      local pairwise = Overload{
        Signature{params={T, T}, returns={String}}
            .. function(a, b) return 'same' end,
        Signature{params={Integer, String}, returns={String}}
            .. function(a, b) return 'mixed' end,
      }
      expect(pairwise(1, 2)).to.be_equal_to('same')
      expect(pairwise('a', 'b')).to.be_equal_to('same')
      -- The generic candidate rejects (1, 'x'); its partial binding
      -- must not leak into the second candidate's check.
      expect(pairwise(1, 'x')).to.be_equal_to('mixed')
    end)

    it('should correlate params and returns of the winning '
      .. 'overload candidate', function()
      local T = TypeVar('T')
      local bad = Overload{
        Signature{params={T}, returns={T}}
            .. function(x) return 'wrong' end,
      }
      expect(pcall(bad, 1)).to.be_false()
      expect(bad('wrong')).to.be_equal_to('wrong')
    end)
  end)

end)

if llx.main_file() then
  unit.run_unit_tests()
end
