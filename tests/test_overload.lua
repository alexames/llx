local unit = require 'llx.unit'
local llx = require 'llx'

local signature_module = require 'llx.signature'
local class_module = require 'llx.class'
local exceptions = require 'llx.exceptions'
local matchers = require 'llx.types.matchers'
local subtype_module = require 'llx.is_subtype'
local types = require 'llx.types'
local isinstance = require 'llx.isinstance' . isinstance

local Function = signature_module.Function
local Overload = signature_module.Overload
local Signature = signature_module.Signature
local class = class_module.class
local signature_compatible = subtype_module.signature_compatible
local Callable = matchers.Callable
local ExceptionGroup = exceptions.ExceptionGroup
local InvalidArgumentException = exceptions.InvalidArgumentException
local OverloadResolutionException =
    exceptions.OverloadResolutionException
local Boolean = types.Boolean
local Integer = types.Integer
local Number = types.Number
local String = types.String

_ENV = unit.create_test_env(_ENV)

describe('Overload', function()
  describe('module exports', function()
    it('should export Overload from llx.signature', function()
      expect(Overload).to_not.be_nil()
    end)

    it('should export OverloadResolutionException from '
      .. 'llx.exceptions', function()
      expect(OverloadResolutionException).to_not.be_nil()
    end)
  end)

  describe('Signature .. binding', function()
    it('should wrap a function into a Function instance', function()
      local bound = Signature{params={Integer}, returns={Integer}}
          .. function(n) return n + 1 end
      expect(isinstance(bound, Function)).to.be_true()
      expect(bound.params[1]).to.be_equal_to(Integer)
      expect(bound.returns[1]).to.be_equal_to(Integer)
    end)

    it('should produce a callable that checks its signature', function()
      local bound = Signature{params={Integer}, returns={Integer}}
          .. function(n) return n + 1 end
      expect(bound(1)).to.be_equal_to(2)
      local ok = pcall(function() bound('nope') end)
      expect(ok).to.be_false()
    end)

    it('should reject a non-callable operand', function()
      local ok = pcall(function()
        return Signature{params={}, returns={}} .. 42
      end)
      expect(ok).to.be_false()
    end)
  end)

  describe('construction', function()
    it('should reject an empty declaration list', function()
      local ok = pcall(function() return Overload{} end)
      expect(ok).to.be_false()
    end)

    it('should reject entries that are not signature-bound '
      .. 'functions', function()
      local ok, err = pcall(function()
        return Overload{function() end}
      end)
      expect(ok).to.be_false()
      expect(tostring(err):find('entry 1', 1, true)).to_not.be_nil()
    end)

    it('should expose the declaration list as overloads', function()
      local first = Signature{params={Integer}, returns={Integer}}
          .. function(n) return n end
      local second = Signature{params={String}, returns={String}}
          .. function(s) return s end
      local overloaded = Overload{first, second}
      expect(#overloaded.overloads).to.be_equal_to(2)
      expect(overloaded.overloads[1]).to.be_equal_to(first)
      expect(overloaded.overloads[2]).to.be_equal_to(second)
    end)
  end)

  describe('dispatch', function()
    it('should dispatch by arity', function()
      local area = Overload{
        Signature{params={Integer}, returns={Integer}}
            .. function(side) return side * side end,
        Signature{params={Integer, Integer}, returns={Integer}}
            .. function(w, h) return w * h end,
      }
      expect(area(3)).to.be_equal_to(9)
      expect(area(3, 4)).to.be_equal_to(12)
    end)

    it('should dispatch by type at the same arity', function()
      local describe_value = Overload{
        Signature{params={Integer}, returns={String}}
            .. function(n) return 'int:' .. tostring(n) end,
        Signature{params={String}, returns={String}}
            .. function(s) return 'str:' .. s end,
      }
      expect(describe_value(7)).to.be_equal_to('int:7')
      expect(describe_value('x')).to.be_equal_to('str:x')
    end)

    it('should pick the first matching declaration when several '
      .. 'match', function()
      -- Number accepts integers too, so declaration order decides.
      local tagged = Overload{
        Signature{params={Number}, returns={String}}
            .. function(n) return 'number' end,
        Signature{params={Integer}, returns={String}}
            .. function(n) return 'integer' end,
      }
      expect(tagged(1)).to.be_equal_to('number')
    end)

    it('should reach a specific declaration listed before a broad '
      .. 'one', function()
      local tagged = Overload{
        Signature{params={Integer}, returns={String}}
            .. function(n) return 'integer' end,
        Signature{params={Number}, returns={String}}
            .. function(n) return 'number' end,
      }
      expect(tagged(1)).to.be_equal_to('integer')
      expect(tagged(1.5)).to.be_equal_to('number')
    end)

    it('should return multiple values from the matched branch',
        function()
      local pair = Overload{
        Signature{params={Integer}, returns={Integer, String}}
            .. function(n) return n, 'int' end,
      }
      local a, b = pair(4)
      expect(a).to.be_equal_to(4)
      expect(b).to.be_equal_to('int')
    end)

    it('should dispatch to a variadic declaration', function()
      local join = Overload{
        Signature{params={String, String}, returns={String}}
            .. function(a, b) return a .. b end,
        Signature{params={Integer, '...'}, returns={Integer}}
            .. function(n, ...) return n + select('#', ...) end,
      }
      expect(join('a', 'b')).to.be_equal_to('ab')
      expect(join(10, 'x', 'y', 'z')).to.be_equal_to(13)
    end)

    it('should skip a variadic declaration whose fixed prefix does '
      .. 'not match', function()
      local pick = Overload{
        Signature{params={Integer, '...'}, returns={String}}
            .. function(...) return 'int-lead' end,
        Signature{params={String, '...'}, returns={String}}
            .. function(...) return 'str-lead' end,
      }
      expect(pick('s', 1, 2)).to.be_equal_to('str-lead')
    end)
  end)

  describe('no-match errors', function()
    local function make_overload()
      return Overload{
        Signature{params={Integer}, returns={Integer}}
            .. function(n) return n end,
        Signature{params={String, String}, returns={String}}
            .. function(a, b) return a .. b end,
      }
    end

    it('should raise OverloadResolutionException when nothing '
      .. 'matches', function()
      local overloaded = make_overload()
      local ok, err = pcall(function() overloaded(true) end)
      expect(ok).to.be_false()
      expect(isinstance(err, OverloadResolutionException)).to.be_true()
    end)

    it('should raise an ExceptionGroup subclass', function()
      local overloaded = make_overload()
      local _, err = pcall(function() overloaded(true) end)
      expect(isinstance(err, ExceptionGroup)).to.be_true()
    end)

    it('should collect one rejection per candidate', function()
      local overloaded = make_overload()
      local _, err = pcall(function() overloaded(true) end)
      expect(#err.exception_list).to.be_equal_to(2)
      expect(isinstance(err.exception_list[1],
                        InvalidArgumentException)).to.be_true()
      expect(isinstance(err.exception_list[2],
                        InvalidArgumentException)).to.be_true()
    end)

    it('should list the candidate signatures in the message', function()
      local overloaded = make_overload()
      local _, err = pcall(function() overloaded(true) end)
      expect(err.what:find('no overload matched', 1, true))
          .to_not.be_nil()
      expect(err.what:find('(Integer) -> (Integer)', 1, true))
          .to_not.be_nil()
      expect(err.what:find('(String, String) -> (String)', 1, true))
          .to_not.be_nil()
    end)

    it('should expose the candidate descriptions', function()
      local overloaded = make_overload()
      local _, err = pcall(function() overloaded(true) end)
      expect(#err.candidates).to.be_equal_to(2)
      expect(err.candidates[1]).to.be_equal_to('(Integer) -> (Integer)')
    end)

    it('should reject calls whose arity matches no candidate',
        function()
      local overloaded = make_overload()
      local ok, err = pcall(function() overloaded(1, 2, 3) end)
      expect(ok).to.be_false()
      expect(isinstance(err, OverloadResolutionException)).to.be_true()
    end)
  end)

  describe('error propagation', function()
    it('should enforce postconditions on the matched branch', function()
      local bad = Overload{
        Signature{params={Integer}, returns={Integer}}
            .. function(n) return 'not an integer' end,
        Signature{params={String}, returns={String}}
            .. function(s) return s end,
      }
      local ok, err = pcall(function() bad(1) end)
      expect(ok).to.be_false()
      -- The failure is the branch's own postcondition error, not a
      -- resolution failure: dispatch already committed to the branch.
      expect(isinstance(err, OverloadResolutionException)).to.be_false()
      expect(isinstance(err, InvalidArgumentException)).to.be_true()
    end)

    it('should not try later declarations after a postcondition '
      .. 'failure', function()
      local reached_second = false
      local bad = Overload{
        Signature{params={Integer}, returns={Integer}}
            .. function(n) return 'wrong' end,
        Signature{params={Integer}, returns={Integer}}
            .. function(n)
              reached_second = true
              return n
            end,
      }
      pcall(function() bad(1) end)
      expect(reached_second).to.be_false()
    end)

    it('should propagate non-argument errors from precondition '
      .. 'checks', function()
      -- A non-trailing '...' is malformed; its ValueException must
      -- propagate rather than count as "candidate did not match".
      local malformed = Overload{
        Signature{params={'...', Integer}, returns={}}
            .. function(...) end,
        Signature{params={Integer}, returns={}}
            .. function(n) end,
      }
      local ok, err = pcall(function() malformed(1) end)
      expect(ok).to.be_false()
      expect(isinstance(err, OverloadResolutionException)).to.be_false()
      expect(tostring(err.what):find('VARARG', 1, true)).to_not.be_nil()
    end)

    it('should propagate errors raised by the matched branch body',
        function()
      local exploding = Overload{
        Signature{params={Integer}, returns={Integer}}
            .. function(n) error('boom', 0) end,
      }
      local ok, err = pcall(function() exploding(1) end)
      expect(ok).to.be_false()
      expect(err).to.be_equal_to('boom')
    end)
  end)

  describe('methods on classes', function()
    -- An Overload is assigned directly to its key (no '|' decorator:
    -- the decorator syntax carries one value per key).
    local OverloadPoint = class 'OverloadPoint' {
      __init = function(self, x, y)
        self.x = x or 0
        self.y = y or 0
      end,

      move = Overload{
        Signature{params={'OverloadPoint', Integer, Integer},
                  returns={}}
            .. function(self, x, y)
              self.x = self.x + x
              self.y = self.y + y
            end,
        Signature{params={'OverloadPoint', 'OverloadPoint'},
                  returns={}}
            .. function(self, other)
              self.x = self.x + other.x
              self.y = self.y + other.y
            end,
      },
    }

    it('should dispatch a method call by argument types', function()
      local p = OverloadPoint(1, 2)
      p:move(10, 20)
      expect(p.x).to.be_equal_to(11)
      expect(p.y).to.be_equal_to(22)
      p:move(OverloadPoint(1, 1))
      expect(p.x).to.be_equal_to(12)
      expect(p.y).to.be_equal_to(23)
    end)

    it('should raise a resolution error for unsupported method '
      .. 'arguments', function()
      local p = OverloadPoint(0, 0)
      local ok, err = pcall(function() p:move('nope') end)
      expect(ok).to.be_false()
      expect(isinstance(err, OverloadResolutionException)).to.be_true()
    end)

    it('should render string type names as themselves in candidate '
      .. 'descriptions', function()
      -- Regression: llx extends the string library, so every string
      -- has __name == 'String'; the describer must not render class
      -- name strings (or the '...' marker) as 'String'.
      local p = OverloadPoint(0, 0)
      local _, err = pcall(function() p:move('nope') end)
      expect(err.what:find(
          '(OverloadPoint, Integer, Integer) -> ()', 1, true))
          .to_not.be_nil()
      expect(err.what:find(
          '(OverloadPoint, OverloadPoint) -> ()', 1, true))
          .to_not.be_nil()
    end)
  end)

  describe('type system integration', function()
    local overloaded = Overload{
      Signature{params={Integer}, returns={Integer}}
          .. function(n) return n end,
      Signature{params={String}, returns={String}}
          .. function(s) return s end,
    }

    it('should satisfy isinstance against types.Function', function()
      expect(isinstance(overloaded, types.Function)).to.be_true()
    end)

    it('should satisfy Callable when any declaration is compatible',
        function()
      expect(isinstance(overloaded, Callable({Integer}, {Integer})))
          .to.be_true()
      expect(isinstance(overloaded, Callable({String}, {String})))
          .to.be_true()
    end)

    it('should fail Callable when no declaration is compatible',
        function()
      expect(isinstance(overloaded, Callable({Boolean}, {Boolean})))
          .to.be_false()
      expect(isinstance(overloaded, Callable({Integer}, {String})))
          .to.be_false()
    end)

    it('should be signature-compatible when any declaration is',
        function()
      expect(signature_compatible(
          overloaded, {params={Integer}, returns={Integer}}))
          .to.be_true()
      expect(signature_compatible(
          overloaded, {params={Boolean}, returns={Boolean}}))
          .to.be_false()
    end)

    it('should require every declaration to be covered when the '
      .. 'overload is the requirement', function()
      local int_only = Signature{params={Integer}, returns={Integer}}
          .. function(n) return n end
      -- A single declaration cannot honor both promises...
      expect(signature_compatible(int_only, overloaded)).to.be_false()
      -- ...but an equivalent overload set can.
      expect(signature_compatible(overloaded, overloaded)).to.be_true()
    end)

    it('should have a tostring listing the candidates', function()
      local text = tostring(overloaded)
      expect(text:find('Overload', 1, true)).to_not.be_nil()
      expect(text:find('(Integer) -> (Integer)', 1, true))
          .to_not.be_nil()
      expect(text:find('(String) -> (String)', 1, true))
          .to_not.be_nil()
    end)

    it('should render a variadic marker as ... in descriptions',
        function()
      local variadic = Overload{
        Signature{params={Integer, '...'}, returns={Integer}}
            .. function(n, ...) return n end,
      }
      expect(tostring(variadic):find('(Integer, ...) -> (Integer)',
                                     1, true)).to_not.be_nil()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
