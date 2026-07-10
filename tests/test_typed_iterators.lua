local unit = require 'llx.unit'
local llx = require 'llx'
local functional = require 'llx.functional'
local typed_iterators = require 'llx.typed_iterators'

local Yields = typed_iterators.Yields
local Generates = typed_iterators.Generates
local IteratorFunction = typed_iterators.IteratorFunction
local GeneratorFunction = typed_iterators.GeneratorFunction
local GeneratorInstance = typed_iterators.GeneratorInstance

local matchers = require 'llx.types.matchers'
local TypeVar = matchers.TypeVar
local VARARG = require 'llx.check_arguments' . VARARG

local class = llx.class
local isinstance = llx.isinstance
local Integer = llx.Integer
local Number = llx.Number
local String = llx.String

_ENV = unit.create_test_env(_ENV)

-- A simple counting iterator closure: yields 1 .. n, then nil.
local function counter(n)
  local i = 0
  return function()
    i = i + 1
    if i <= n then return i end
  end
end

-- An iterator closure yielding (index, name) pairs.
local function named(names)
  local i = 0
  return function()
    i = i + 1
    if names[i] ~= nil then return i, names[i] end
  end
end

describe('typed_iterators', function()
  describe('module exports', function()
    it('should export the wrapper and declaration classes', function()
      expect(Yields).to_not.be_nil()
      expect(Generates).to_not.be_nil()
      expect(IteratorFunction).to_not.be_nil()
      expect(GeneratorFunction).to_not.be_nil()
      expect(GeneratorInstance).to_not.be_nil()
    end)

    it('should be accessible via llx.typed_iterators', function()
      expect(llx.typed_iterators).to_not.be_nil()
      expect(llx.typed_iterators.Yields).to.be_equal_to(Yields)
      expect(llx.typed_iterators.Generates).to.be_equal_to(Generates)
    end)
  end)

  describe('Yields declaration', function()
    it('should bind a closure into an IteratorFunction', function()
      local wrapped = Yields{Integer} .. counter(3)
      expect(isinstance(wrapped, IteratorFunction)).to.be_true()
    end)

    it('should expose the declared yield types', function()
      local yields = {Integer, String}
      local wrapped = Yields(yields) .. named{'a'}
      expect(wrapped.yields).to.be_equal_to(yields)
    end)

    it('should bind with the closure on either side', function()
      local wrapped = counter(1) .. Yields{Integer}
      expect(isinstance(wrapped, IteratorFunction)).to.be_true()
      expect(wrapped()).to.be_equal_to(1)
    end)

    it('should reject a non-callable binding', function()
      expect(function() return Yields{Integer} .. 42 end)
        .to.throw('Yields: expected a callable to bind, got number')
    end)

    it('should reject a non-table yield list', function()
      expect(function() return Yields('Integer') end)
        .to.throw('Yields: expected a list of yield types')
    end)
  end)

  describe('IteratorFunction per-step checking', function()
    it('should pass through values that satisfy the yield '
      .. 'types', function()
      local wrapped = Yields{Integer} .. counter(3)
      expect(wrapped()).to.be_equal_to(1)
      expect(wrapped()).to.be_equal_to(2)
      expect(wrapped()).to.be_equal_to(3)
      expect(wrapped()).to.be_nil()
    end)

    it('should raise on a step yielding the wrong type', function()
      local wrapped = Yields{String} .. counter(1)
      expect(function() wrapped() end).to.throw()
    end)

    it('should anchor per-step failures at the driving loop, '
      .. 'not the check machinery', function()
      -- Issue #67: the exception used to carry a traceback anchored
      -- inside check_boundary's pcall; it is re-anchored at the
      -- first frame outside llx.typed_iterators (the user's loop or
      -- explicit step call).
      local wrapped = Yields{String} .. counter(1)
      -- Not a tail call: the calling frame must stay live so the
      -- traceback can name it.
      local ok, err = pcall(function() wrapped() end)
      expect(ok).to.be_false()
      local first_frame =
          err.traceback:match('stack traceback:%s*([^\n]*)')
      expect(first_frame).to_not.be_nil()
      -- The first frame must be this test file. (A negative check
      -- for 'typed_iterators.lua' would be self-defeating: it is a
      -- substring of this file's own name.)
      expect(first_frame:find('test_typed_iterators', 1, true))
          .to_not.be_nil()
    end)

    it('should raise on the offending step only', function()
      local values = {1, 2, 'three'}
      local i = 0
      local wrapped = Yields{Integer} .. function()
        i = i + 1
        return values[i]
      end
      expect(wrapped()).to.be_equal_to(1)
      expect(wrapped()).to.be_equal_to(2)
      expect(function() wrapped() end).to.throw()
    end)

    it('should check multi-value yield tuples', function()
      local wrapped = Yields{Integer, String} .. named{'a', 'b'}
      local i, name = wrapped()
      expect(i).to.be_equal_to(1)
      expect(name).to.be_equal_to('a')
    end)

    it('should reject extra values beyond the declared '
      .. 'tuple', function()
      local wrapped = Yields{Integer} .. function()
        return 1, 'extra'
      end
      expect(function() wrapped() end).to.throw()
    end)

    it('should allow extra values through a variadic tail', function()
      local wrapped = Yields{Integer, VARARG} .. function()
        return 1, 'extra', true
      end
      local a, b, c = wrapped()
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to('extra')
      expect(c).to.be_true()
    end)

    it('should pass the termination step through unchecked', function()
      -- The nil terminator can never satisfy the yield types; it is
      -- the protocol's end-of-iteration signal, not a yielded tuple.
      local wrapped = Yields{String} .. function() return nil end
      expect(wrapped()).to.be_nil()
    end)

    it('should work in a generic-for loop', function()
      local wrapped = Yields{Integer} .. counter(4)
      local total = 0
      for v in wrapped do
        total = total + v
      end
      expect(total).to.be_equal_to(10)
    end)

    it('should forward generic-for state and control '
      .. 'arguments', function()
      -- A control-driven closure (the shape llx.functional's filter
      -- produces) only advances correctly when (state, control) are
      -- forwarded.
      local wrapped = Yields{Integer, Integer} .. function(_, control)
        control = (control or 0) + 1
        if control <= 3 then return control, control * 10 end
      end
      local seen = {}
      for i, v in wrapped do
        seen[i] = v
      end
      expect(#seen).to.be_equal_to(3)
      expect(seen[3]).to.be_equal_to(30)
    end)

    it('should round-trip llx.functional iterators', function()
      -- range yields (index, value) pairs; wrap the produced closure
      -- and consume it through generic-for.
      local wrapped = Yields{Integer, Integer} .. functional.range(5)
      local values = {}
      for _, v in wrapped do
        values[#values + 1] = v
      end
      expect(#values).to.be_equal_to(4)
      expect(values[1]).to.be_equal_to(1)
      expect(values[4]).to.be_equal_to(4)
    end)

    it('should catch a lying llx.functional pipeline', function()
      local wrapped = Yields{Integer, Integer}
          .. functional.filter(function() return true end,
                               named{'a', 'b'})
      expect(function() wrapped(nil, nil) end).to.throw()
    end)

    it('should enforce TypeVar consistency within one step', function()
      local T = TypeVar('T')
      local pairs_of = function(a, b)
        local done = false
        return function()
          if done then return nil end
          done = true
          return a, b
        end
      end
      local ok_wrapped = Yields{T, T} .. pairs_of(1, 2)
      local a, b = ok_wrapped()
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      local bad_wrapped = Yields{T, T} .. pairs_of(1, 'x')
      expect(function() bad_wrapped() end).to.throw()
    end)

    it('should bind TypeVars per step, not across steps', function()
      local T = TypeVar('T')
      local values = {1, 'one'}
      local i = 0
      local wrapped = Yields{T} .. function()
        i = i + 1
        return values[i]
      end
      -- Each step opens a fresh binding scope, so a step yielding an
      -- Integer does not constrain a later step yielding a String.
      expect(wrapped()).to.be_equal_to(1)
      expect(wrapped()).to.be_equal_to('one')
    end)
  end)

  describe('Generates declaration', function()
    it('should bind a body into a GeneratorFunction', function()
      local gen = Generates{yields = {Integer}} .. function()
        coroutine.yield(1)
      end
      expect(isinstance(gen, GeneratorFunction)).to.be_true()
    end)

    it('should default missing contract lists to empty', function()
      local gen = Generates{} .. function() end
      expect(#gen.yields).to.be_equal_to(0)
      expect(#gen.accepts).to.be_equal_to(0)
      expect(#gen.returns).to.be_equal_to(0)
    end)

    it('should reject unknown contract keys', function()
      expect(function() return Generates{sends = {Integer}} end)
        .to.throw("Generates: unknown contract key 'sends'")
    end)

    it('should reject a non-table contract', function()
      expect(function() return Generates('Integer') end)
        .to.throw('Generates: expected a contract table with '
          .. 'optional yields, accepts, and returns lists')
    end)

    it('should reject a non-callable binding', function()
      expect(function() return Generates{} .. 42 end)
        .to.throw('Generates: expected a callable to bind, '
          .. 'got number')
    end)
  end)

  describe('GeneratorInstance', function()
    local function count_up(n)
      return Generates{yields = {Integer}} .. function(limit)
        for i = 1, limit do
          coroutine.yield(i)
        end
      end
    end

    it('should create a suspended instance per call', function()
      local gen = count_up()
      local instance = gen(2)
      expect(isinstance(instance, GeneratorInstance)).to.be_true()
      expect(instance:status()).to.be_equal_to('suspended')
      -- Independent instances do not share state.
      local other = gen(2)
      expect(instance()).to.be_equal_to(1)
      expect(other()).to.be_equal_to(1)
    end)

    it('should yield checked values on resume', function()
      local instance = count_up()(3)
      expect(instance()).to.be_equal_to(1)
      expect(instance()).to.be_equal_to(2)
      expect(instance()).to.be_equal_to(3)
      expect(instance()).to.be_nil()
      expect(instance:status()).to.be_equal_to('dead')
    end)

    it('should raise when the body yields the wrong type', function()
      local gen = Generates{yields = {String}} .. function()
        coroutine.yield(42)
      end
      local instance = gen()
      expect(function() instance() end).to.throw()
    end)

    it('should anchor yield failures outside the generator '
      .. 'machinery', function()
      -- The generic-for path is one frame deeper than the iterator
      -- path (__call -> resume -> check_boundary); the re-anchoring
      -- walk must still land on the user's frame (issue #67).
      local gen = Generates{yields = {String}} .. function()
        coroutine.yield(42)
      end
      local instance = gen()
      -- Not a tail call: the calling frame must stay live so the
      -- traceback can name it.
      local ok, err = pcall(function() instance() end)
      expect(ok).to.be_false()
      local first_frame =
          err.traceback:match('stack traceback:%s*([^\n]*)')
      expect(first_frame).to_not.be_nil()
      expect(first_frame:find('test_typed_iterators', 1, true))
          .to_not.be_nil()
    end)

    it('should work in a generic-for loop', function()
      local instance = count_up()(4)
      local total = 0
      for v in instance do
        total = total + v
      end
      expect(total).to.be_equal_to(10)
    end)

    it('should check sent values through send', function()
      local seen
      local gen = Generates{yields = {Integer}, accepts = {String}}
          .. function()
        seen = coroutine.yield(1)
        coroutine.yield(2)
      end
      local instance = gen()
      expect(instance()).to.be_equal_to(1)
      expect(instance:send('hello')).to.be_equal_to(2)
      expect(seen).to.be_equal_to('hello')
    end)

    it('should raise when a sent value has the wrong type', function()
      local gen = Generates{yields = {Integer}, accepts = {String}}
          .. function()
        coroutine.yield(1)
        coroutine.yield(2)
      end
      local instance = gen()
      instance()
      expect(function() instance:send(42) end).to.throw()
    end)

    it('should reject sending values to a just-started '
      .. 'generator', function()
      local instance = count_up()(1)
      expect(function() instance:send('early') end)
        .to.throw('GeneratorInstance: cannot send values to a '
          .. 'just-started generator; resume it once first')
    end)

    it('should let a value-less send start the body', function()
      -- The Python analog: only send(None) is legal on a
      -- just-started generator, and it behaves as a plain resume;
      -- the accepts contract does not apply to starting the body.
      local gen = Generates{yields = {Integer}, accepts = {String}}
          .. function()
        coroutine.yield(1)
      end
      local instance = gen()
      expect(instance:send()).to.be_equal_to(1)
    end)

    it('should raise when sending to a dead generator', function()
      local gen = Generates{accepts = {String}} .. function() end
      local instance = gen()
      instance()
      expect(function() instance:send('late') end).to.throw()
    end)

    it('should leave a variadic accepts tail unchecked', function()
      local seen
      local gen = Generates{yields = {Integer},
                            accepts = {String, VARARG}}
          .. function()
        seen = table.pack(coroutine.yield(1))
        coroutine.yield(2)
      end
      local instance = gen()
      instance()
      expect(instance:send('tag', 1, true)).to.be_equal_to(2)
      expect(seen.n).to.be_equal_to(3)
      expect(seen[1]).to.be_equal_to('tag')
      expect(function()
        local other = gen()
        other()
        other:send(42, 'extras')
      end).to.throw()
    end)

    it('should not treat plain-call arguments as sends', function()
      -- Generic-for drives the instance with (state, control)
      -- arguments; the accepts contract applies only to explicit
      -- send calls, so the loop protocol never trips it.
      local gen = Generates{yields = {Integer}, accepts = {String}}
          .. function()
        coroutine.yield(1)
        coroutine.yield(2)
      end
      local instance = gen()
      local seen = {}
      for v in instance do
        seen[#seen + 1] = v
      end
      expect(#seen).to.be_equal_to(2)
    end)

    it('should check final return values against returns', function()
      local gen = Generates{yields = {Integer}, returns = {String}}
          .. function()
        coroutine.yield(1)
        return 'done'
      end
      local instance = gen()
      expect(instance()).to.be_equal_to(1)
      expect(instance()).to.be_equal_to('done')
      expect(instance:status()).to.be_equal_to('dead')
    end)

    it('should raise when the body returns the wrong type', function()
      local gen = Generates{returns = {String}} .. function()
        return 42
      end
      local instance = gen()
      expect(function() instance() end).to.throw()
    end)

    it('should raise when the body returns extra values', function()
      local gen = Generates{returns = {String}} .. function()
        return 'done', 'extra'
      end
      local instance = gen()
      expect(function() instance() end).to.throw()
    end)

    it('should leave a variadic returns tail unchecked', function()
      local gen = Generates{returns = {String, VARARG}} .. function()
        return 'done', 1, 2, 3
      end
      local instance = gen()
      local a, b, c, d = instance()
      expect(a).to.be_equal_to('done')
      expect(d).to.be_equal_to(3)
    end)

    it('should propagate errors raised inside the body', function()
      local gen = Generates{} .. function()
        error('boom')
      end
      local instance = gen()
      expect(function() instance() end).to.throw('boom')
    end)

    it('should raise when resuming a dead generator', function()
      local instance = (Generates{} .. function() end)()
      instance()
      expect(function() instance() end).to.throw()
    end)
  end)

  describe('class decorator integration', function()
    it('should wrap a member as a typed iterator closure', function()
      -- The Yields decorator form treats the member itself as the
      -- iterator closure: each call is one step, with self arriving
      -- in the state slot.
      local Steps = class 'TypedIterSteps' {
        __init = function(self)
          self.i = 0
        end,

        ['next_value' | Yields{Integer}] = function(self)
          self.i = self.i + 1
          if self.i <= 2 then return self.i end
        end,
      }
      local steps = Steps()
      expect(steps:next_value()).to.be_equal_to(1)
      expect(steps:next_value()).to.be_equal_to(2)
      expect(steps:next_value()).to.be_nil()
      local Lying = class 'TypedIterStepsBad' {
        ['next_value' | Yields{String}] = function(self)
          return 42
        end,
      }
      local lying = Lying()
      expect(function() lying:next_value() end).to.throw()
    end)

    it('should wrap a member as a typed coroutine factory', function()
      local Machine = class 'TypedGenMachine' {
        __init = function(self, factor)
          self.factor = factor
        end,

        ['scaled' | Generates{yields = {Integer}}] =
            function(self, n)
          for i = 1, n do
            coroutine.yield(i * self.factor)
          end
        end,
      }
      local machine = Machine(10)
      local results = {}
      for v in machine:scaled(3) do
        results[#results + 1] = v
      end
      expect(#results).to.be_equal_to(3)
      expect(results[3]).to.be_equal_to(30)
    end)

    it('should enforce the contract through the member', function()
      local Machine = class 'TypedGenMachineBad' {
        ['broken' | Generates{yields = {String}}] = function(self)
          coroutine.yield(123)
        end,
      }
      local machine = Machine()
      local instance = machine:broken()
      expect(function() instance() end).to.throw()
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
