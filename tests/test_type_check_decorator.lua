local unit = require 'llx.unit'
local llx = require 'llx'

local type_check_decorator_module = require 'llx.type_check_decorator'
local type_check_decorator = type_check_decorator_module.type_check_decorator
local types = require 'llx.types'

local Integer = types.Integer
local Number = types.Number
local String = types.String
local Boolean = types.Boolean
local Table = types.Table

_ENV = unit.create_test_env(_ENV)

describe('type_check_decorator', function()
  describe('pass-through with no expected types', function()
    it('should return the original function when '
      .. 'expected_types is nil', function()
      local function my_func(x) return x + 1 end
      local result = type_check_decorator(my_func, nil)
      expect(result).to.be_equal_to(my_func)
    end)

    it('should return the original function when '
      .. 'expected_types is false', function()
      local function my_func(x) return x + 1 end
      local result = type_check_decorator(my_func, false)
      expect(result).to.be_equal_to(my_func)
    end)
  end)

  describe('argument type checking', function()
    it('should pass when argument types match', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {args={Integer, Integer}})
      local success, result = pcall(wrapped, 1, 2)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(3)
    end)

    it('should error when first argument type is wrong', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {args={Integer, Integer}})
      local success = pcall(wrapped, 'hello', 2)
      expect(success).to.be_false()
    end)

    it('should error when second argument type is wrong', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {args={Integer, Integer}})
      local success = pcall(wrapped, 1, 'hello')
      expect(success).to.be_false()
    end)

    it('should error when argument is nil but type is expected', function()
      local function identity(a) return a end
      local wrapped = type_check_decorator(identity, {args={Integer}})
      local success = pcall(wrapped, nil)
      expect(success).to.be_false()
    end)

    it('should pass when string argument matches String type', function()
      local function greet(name) return 'hello ' .. name end
      local wrapped = type_check_decorator(greet, {args={String}})
      local success, result = pcall(wrapped, 'world')
      expect(success).to.be_true()
      expect(result).to.be_equal_to('hello world')
    end)

    it('should error when number given but String expected', function()
      local function greet(name) return 'hello ' .. name end
      local wrapped = type_check_decorator(greet, {args={String}})
      local success = pcall(wrapped, 42)
      expect(success).to.be_false()
    end)

    it('should only check types up to the length of args list', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {args={Integer}})
      -- Only first argument is checked; second can be anything
      local success, result = pcall(wrapped, 1, 2)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(3)
    end)

    it('should pass with no args specification but '
      .. 'returns specified', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {returns={Integer}})
      -- No argument checking, so any args are fine
      local success, result = pcall(wrapped, 1, 2)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(3)
    end)
  end)

  describe('return type checking', function()
    it('should pass when return type matches', function()
      local function get_number() return 42 end
      local wrapped = type_check_decorator(get_number, {returns={Integer}})
      local success, result = pcall(wrapped)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(42)
    end)

    it('should error when return type does not match', function()
      local function get_string() return 'hello' end
      local wrapped = type_check_decorator(get_string, {returns={Integer}})
      local success = pcall(wrapped)
      expect(success).to.be_false()
    end)

    it('should check multiple return values', function()
      local function get_pair() return 1, 'hello' end
      local wrapped = type_check_decorator(
        get_pair, {returns={Integer, String}})
      local success, r1, r2 = pcall(wrapped)
      expect(success).to.be_true()
      expect(r1).to.be_equal_to(1)
      expect(r2).to.be_equal_to('hello')
    end)

    it('should error on second return value type mismatch', function()
      local function get_pair() return 1, 2 end
      local wrapped = type_check_decorator(
        get_pair, {returns={Integer, String}})
      local success = pcall(wrapped)
      expect(success).to.be_false()
    end)
  end)

  describe('combined argument and return type checking', function()
    it('should pass when both args and returns match', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {
        args={Integer, Integer},
        returns={Integer},
      })
      local success, result = pcall(wrapped, 1, 2)
      expect(success).to.be_true()
      expect(result).to.be_equal_to(3)
    end)

    it('should error on argument mismatch even if return '
      .. 'would be valid', function()
      local function add(a, b) return a + b end
      local wrapped = type_check_decorator(add, {
        args={Integer, Integer},
        returns={Number},
      })
      local success = pcall(wrapped, 'x', 2)
      expect(success).to.be_false()
    end)

    it('should error on return mismatch even if args are valid', function()
      local function to_string(n) return tostring(n) end
      local wrapped = type_check_decorator(to_string, {
        args={Integer},
        returns={Integer},
      })
      local success = pcall(wrapped, 42)
      expect(success).to.be_false()
    end)
  end)

  describe('wrapped function behavior', function()
    it('should return a different function when '
      .. 'expected_types is given', function()
      local function my_func() end
      local wrapped = type_check_decorator(my_func, {args={}, returns={}})
      expect(type(wrapped)).to.be_equal_to('function')
    end)

    it('should forward all arguments to the underlying function', function()
      local captured_args = {}
      local function capture(...)
        captured_args = {...}
        return 1
      end
      local wrapped = type_check_decorator(
        capture,
        {args={Integer, Integer, Integer},
         returns={Integer}})
      wrapped(10, 20, 30)
      expect(captured_args[1]).to.be_equal_to(10)
      expect(captured_args[2]).to.be_equal_to(20)
      expect(captured_args[3]).to.be_equal_to(30)
    end)

    it('should forward all return values from the '
      .. 'underlying function', function()
      local function multi_return() return 1, 2, 3 end
      local wrapped = type_check_decorator(
        multi_return,
        {returns={Integer, Integer, Integer}})
      local a, b, c = wrapped()
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)
  end)

  describe('access via llx module', function()
    it('should be accessible as llx.type_check_decorator', function()
      expect(llx.type_check_decorator).to_not.be_nil()
    end)

    it('should have the type_check_decorator function', function()
      expect(llx.type_check_decorator.type_check_decorator).to_not.be_nil()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
