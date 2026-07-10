local unit = require 'llx.unit'
local llx = require 'llx'
local check_arguments_module = require 'llx.check_arguments'
require 'llx.types'
require 'llx.schema'

local check_arguments = check_arguments_module.check_arguments
local List = llx.List
local Set = llx.Set
local Schema = llx.Schema
local Number = llx.Number
local Integer = llx.Integer
local Float = llx.Float
local Boolean = llx.Boolean
local Table = llx.Table
local String = llx.String

_ENV = unit.create_test_env(_ENV)

describe('check_arguments', function()
  describe('numbers', function()
    it('should succeed with valid numbers', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, 2, 3)
      expect(success).to.be_true()
    end)

    it('should fail when first argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, {}, 2, 3)
      expect(success).to.be_false()
    end)

    it('should fail when middle argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, {}, 3)
      expect(success).to.be_false()
    end)

    it('should fail when last argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, 2, {})
      expect(success).to.be_false()
    end)

    it('should fail when all arguments are invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, {}, {}, {})
      expect(success).to.be_false()
    end)
  end)

  describe('integers and numbers', function()
    it('should succeed when last is integer', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2.0, 3)
      expect(success).to.be_true()
    end)

    it('should succeed when last is float', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2.0, 3.0)
      expect(success).to.be_true()
    end)

    it('should fail when float expected but integer provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2, 3)
      expect(success).to.be_false()
    end)

    it('should fail when integer expected but float provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1.0, 2.0, 3)
      expect(success).to.be_false()
    end)

    it('should fail when wrong type provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, {}, {}, 3)
      expect(success).to.be_false()
    end)
  end)

  describe('boolean', function()
    it('should succeed with true', function()
      local success = pcall(function(b)
        check_arguments{b=Boolean}
      end, true)
      expect(success).to.be_true()
    end)

    it('should succeed with false', function()
      local success = pcall(function(b)
        check_arguments{b=Boolean}
      end, false)
      expect(success).to.be_true()
    end)
  end)

  describe('table', function()
    it('should succeed with valid table', function()
      local success = pcall(function(t)
        check_arguments{t=Table}
      end, {})
      expect(success).to.be_true()
    end)

    it('should fail with non-table', function()
      local success = pcall(function(t)
        check_arguments{t=Table}
      end, true)
      expect(success).to.be_false()
    end)
  end)

  describe('list', function()
    it('should succeed with valid list', function()
      local success = pcall(function(t)
        check_arguments{t=List}
      end, List{})
      expect(success).to.be_true()
    end)

    it('should fail with table instead of list', function()
      local success = pcall(function(t)
        check_arguments{t=List}
      end, {})
      expect(success).to.be_false()
    end)
  end)

  describe('check_returns_exact', function()
    local check_returns_exact = check_arguments_module.check_returns_exact
    local VARARG = check_arguments_module.VARARG

    it('should export the VARARG marker', function()
      expect(VARARG).to.be_equal_to('...')
    end)

    it('should pass with exactly the declared count', function()
      local success = pcall(function()
        check_returns_exact({Integer, String}, {1, 'a'}, 2)
      end)
      expect(success).to.be_true()
    end)

    it('should pass with fewer values when the types allow nil',
        function()
      local Optional = require 'llx.types.matchers' . Optional
      local success = pcall(function()
        check_returns_exact({Integer, Optional(Integer)}, {1}, 1)
      end)
      expect(success).to.be_true()
    end)

    it('should error when count exceeds the declared list', function()
      local success, err = pcall(function()
        check_returns_exact({Integer}, {1, 'extra'}, 2)
      end)
      expect(success).to.be_false()
      expect(err.what:find('expected at most 1 value(s), got 2', 1, true))
        .to_not.be_nil()
    end)

    it('should trust the explicit count over the table length',
        function()
      -- {1, nil, nil} has # == 1, but a caller counting with
      -- select('#', ...) passes 3.
      local success = pcall(function()
        check_returns_exact({Integer}, {1, nil, nil}, 3)
      end)
      expect(success).to.be_false()
    end)

    it('should allow any count with a trailing VARARG marker', function()
      local success = pcall(function()
        check_returns_exact({Integer, VARARG}, {1, 'a', {}, false}, 4)
      end)
      expect(success).to.be_true()
    end)

    it('should still check the fixed prefix of a VARARG list', function()
      local success = pcall(function()
        check_returns_exact({Integer, VARARG}, {'bad', 'a'}, 2)
      end)
      expect(success).to.be_false()
    end)

    it('should error on a VARARG marker before the last entry',
        function()
      local success, err = pcall(function()
        check_returns_exact({Integer, VARARG, Integer}, {1, 2, 3}, 3)
      end)
      expect(success).to.be_false()
      expect(err.what:find('must be the last entry', 1, true))
        .to_not.be_nil()
    end)

    it('should error on a Rest(T) marker anywhere in the list',
        function()
      -- Rest(T) is the typed-tail marker for Tuple element lists;
      -- it has no __isinstance, so a position holding one could
      -- never match. It must fail loudly rather than silently.
      local Rest = require 'llx.types.matchers' . Rest
      for _, expected_types in ipairs({
        {Rest(Integer)},
        {Integer, Rest(Integer)},
        {Rest(Integer), Integer},
      }) do
        local success, err = pcall(function()
          check_returns_exact(expected_types, {1, 2}, 2)
        end)
        expect(success).to.be_false()
        expect(err.what:find('Rest(T) is only valid inside Tuple',
                             1, true)).to_not.be_nil()
      end
    end)
  end)

  describe('mismatch messages', function()
    -- Diagnostic-quality pins for issue #67: string-named expected
    -- types render as themselves (not 'String'), and class instances
    -- and class objects are called out explicitly on the actual side.
    local function message_of(expected_types, ...)
      local ok, err = pcall(function(x)
        check_arguments{x=expected_types}
      end, ...)
      expect(ok).to.be_false()
      return err.what
    end

    it('should name a string-declared expected type by its value',
        function()
      local what = message_of('MyClass', 42)
      expect(what:find('MyClass expected, got Number', 1, true))
          .to_not.be_nil()
    end)

    it('should keep the class name for primitive actual values',
        function()
      local what = message_of(Integer, 'hi')
      expect(what:find('Integer expected, got String', 1, true))
          .to_not.be_nil()
    end)

    it('should describe a class instance as an instance of its class',
        function()
      local Animal = llx.class 'Animal' {}
      local what = message_of(Integer, Animal())
      expect(what:find(
          'Integer expected, got an instance of Animal', 1, true))
          .to_not.be_nil()
    end)

    it('should describe a class object as the class itself', function()
      local Animal = llx.class 'Animal' {}
      local what = message_of(Integer, Animal)
      expect(what:find(
          'Integer expected, got the class Animal', 1, true))
          .to_not.be_nil()
    end)

    it('should raise clearly for a non-matcher declared type',
        function()
      local ok, err = pcall(function(x)
        check_arguments{x=42}
      end, 1)
      expect(ok).to.be_false()
      expect(err.what:find(
          'expected a type matcher or class with __isinstance',
          1, true)).to_not.be_nil()
    end)
  end)

  describe('undeclared parameters', function()
    -- Regression pins for issue #91: the expected_type == nil branch
    -- used to construct InvalidArgumentException with the wrong arity
    -- (a class table landed in the level slot), so hitting it raised
    -- an arithmetic error instead of a diagnostic.
    local InvalidArgumentException =
        llx.exceptions.InvalidArgumentException

    it('should raise InvalidArgumentException naming the parameter',
        function()
      local ok, err = pcall(function(a, b)
        check_arguments{a=Number}
      end, 1, 2)
      expect(ok).to.be_false()
      expect(llx.isinstance(err, InvalidArgumentException)).to.be_true()
      expect(err.what:find('bad argument #2', 1, true)).to_not.be_nil()
      expect(err.what:find(
          "parameter 'b' has no declared type (got Number)", 1, true))
          .to_not.be_nil()
    end)

    it('should describe the undeclared value like a mismatch would',
        function()
      local Animal = llx.class 'Animal' {}
      local ok, err = pcall(function(pet)
        check_arguments{}
      end, Animal())
      expect(ok).to.be_false()
      expect(llx.isinstance(err, InvalidArgumentException)).to.be_true()
      expect(err.what:find(
          "parameter 'pet' has no declared type "
          .. '(got an instance of Animal)', 1, true))
          .to_not.be_nil()
    end)

    it('should still pass when every parameter is declared', function()
      local ok = pcall(function(a, b)
        check_arguments{a=Number, b=Number}
      end, 1, 2)
      expect(ok).to.be_true()
    end)
  end)

  describe('TypeVar binding scopes', function()
    local matchers = require 'llx.types.matchers'
    local TypeVar = matchers.TypeVar
    local ListOf = matchers.ListOf

    it('should correlate a TypeVar across parameters', function()
      local T = TypeVar('T')
      local function check(a, b)
        check_arguments{a=T, b=T}
      end
      expect(pcall(check, 1, 2)).to.be_true()
      expect(pcall(check, 'a', 'b')).to.be_true()
      expect(pcall(check, 1, 'x')).to.be_false()
      -- Numbers bind narrowly: an Integer witness rejects a Float,
      -- matching the signature path.
      expect(pcall(check, 1, 1.5)).to.be_false()
    end)

    it('should propagate bindings through parameterized matchers',
        function()
      local T = TypeVar('T')
      local function check(xs, x)
        check_arguments{xs=ListOf(T), x=T}
      end
      expect(pcall(check, {1, 2}, 3)).to.be_true()
      expect(pcall(check, {1, 2}, 'x')).to.be_false()
    end)

    it('should enforce a declared bound', function()
      local N = TypeVar('N', {bound=Number})
      local function check(n)
        check_arguments{n=N}
      end
      expect(pcall(check, 1)).to.be_true()
      expect(pcall(check, 'not a number')).to.be_false()
    end)

    it('should exit the scope on success and on failure', function()
      local T = TypeVar('T')
      local function check(a, b)
        check_arguments{a=T, b=T}
      end
      expect(pcall(check, 1, 'x')).to.be_false()
      -- The scope was exited: plain isinstance is back to the
      -- unconstrained behavior, and each call re-binds from scratch.
      expect(llx.isinstance('anything', T)).to.be_true()
      expect(pcall(check, 'a', 'b')).to.be_true()
      expect(pcall(check, 2, 3)).to.be_true()
    end)
  end)

  describe('schema', function()
    it('should succeed with number schema and valid number', function()
      local schema = Schema{type=Number}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, 1)
      expect(success).to.be_true()
    end)

    it('should fail with number schema and invalid value', function()
      local schema = Schema{type=Number}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, '')
      expect(success).to.be_false()
    end)

    it('should succeed with table schema and valid table', function()
      local schema = Schema{type=Table}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, {})
      expect(success).to.be_true()
    end)

    it('should succeed with table schema with properties', function()
      local schema = Schema{
        type=Table,
        properties={
          b={type=Boolean},
          n={type=Number},
          s={type=String},
          t={
            type=Table,
            properties={
              l={type=List},
              s={type=Set},
           },
          },
        },
      }
      local success = pcall(function(arg)
        check_arguments{arg=schema}
      end, {b=true, n=10, s='', t={l=List{1,2,3},s=Set{'a', 'b', 'c'}}})
      expect(success).to.be_true()
    end)

    it('should fail with table schema and non-table', function()
      local schema = Schema{type=Table}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, 1)
      expect(success).to.be_false()
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
