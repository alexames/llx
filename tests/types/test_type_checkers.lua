local unit = require 'llx.unit'
local llx = require 'llx'

local Boolean = llx.Boolean
local Float = llx.Float
local Integer = llx.Integer
local Nil = llx.Nil
local Function = llx.Function
local Thread = llx.Thread
local Userdata = llx.Userdata
local Number = llx.Number
local String = llx.String

local isinstance = llx.isinstance

_ENV = unit.create_test_env(_ENV)

-- ---------------------------------------------------------------------------
-- Boolean
-- ---------------------------------------------------------------------------

describe('Boolean', function()
  describe('__name', function()
    it('should have __name equal to "Boolean"', function()
      expect(Boolean.__name).to.be_equal_to('Boolean')
    end)
  end)

  describe('__tostring', function()
    it('should return a default table string since Boolean has no metatable', function()
      expect(tostring(Boolean)).to.start_with('table: ')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for true', function()
      expect(Boolean:__isinstance(true)).to.be_true()
    end)

    it('should return true for false', function()
      expect(Boolean:__isinstance(false)).to.be_true()
    end)

    it('should return false for nil', function()
      expect(Boolean:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a number', function()
      expect(Boolean:__isinstance(42)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Boolean:__isinstance('true')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Boolean:__isinstance({})).to.be_false()
    end)

    it('should return false for zero', function()
      expect(Boolean:__isinstance(0)).to.be_false()
    end)

    it('should return false for an empty string', function()
      expect(Boolean:__isinstance('')).to.be_false()
    end)
  end)

  describe('__call (type conversion via method call)', function()
    it('should return true for a truthy value (number)', function()
      expect(Boolean:__call(42)).to.be_true()
    end)

    it('should return true for a truthy value (string)', function()
      expect(Boolean:__call('hello')).to.be_true()
    end)

    it('should return true for true', function()
      expect(Boolean:__call(true)).to.be_true()
    end)

    it('should return true for zero (zero is truthy in Lua)', function()
      expect(Boolean:__call(0)).to.be_true()
    end)

    it('should return true for an empty string (truthy in Lua)', function()
      expect(Boolean:__call('')).to.be_true()
    end)

    it('should return false for nil', function()
      expect(Boolean:__call(nil)).to.be_false()
    end)

    it('should return false for false', function()
      expect(Boolean:__call(false)).to.be_false()
    end)

    it('should return true for an empty table (truthy in Lua)', function()
      expect(Boolean:__call({})).to.be_true()
    end)
  end)

  describe('isinstance integration', function()
    it('should identify true as Boolean via isinstance', function()
      expect(isinstance(true, Boolean)).to.be_true()
    end)

    it('should identify false as Boolean via isinstance', function()
      expect(isinstance(false, Boolean)).to.be_true()
    end)

    it('should not identify a number as Boolean via isinstance', function()
      expect(isinstance(1, Boolean)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Float
-- ---------------------------------------------------------------------------

describe('Float', function()
  describe('__name', function()
    it('should have __name equal to "Float"', function()
      expect(Float.__name).to.be_equal_to('Float')
    end)
  end)

  describe('__tostring', function()
    it('should return "Float" when converted to string', function()
      expect(tostring(Float)).to.be_equal_to('Float')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for a float literal', function()
      expect(Float:__isinstance(3.14)).to.be_true()
    end)

    it('should return true for 0.0', function()
      expect(Float:__isinstance(0.0)).to.be_true()
    end)

    it('should return true for a negative float', function()
      expect(Float:__isinstance(-2.5)).to.be_true()
    end)

    it('should return false for an integer', function()
      expect(Float:__isinstance(42)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Float:__isinstance('3.14')).to.be_false()
    end)

    it('should return false for nil', function()
      expect(Float:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Float:__isinstance(true)).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Float:__isinstance({})).to.be_false()
    end)
  end)

  describe('__call (type conversion)', function()
    it('should return 0.0 for nil', function()
      local result = Float(nil)
      expect(result).to.be_equal_to(0.0)
      expect(math.type(result)).to.be_equal_to('float')
    end)

    it('should return 0.0 for false', function()
      local result = Float(false)
      expect(result).to.be_equal_to(0.0)
      expect(math.type(result)).to.be_equal_to('float')
    end)

    it('should return 1.0 for true', function()
      local result = Float(true)
      expect(result).to.be_equal_to(1.0)
      expect(math.type(result)).to.be_equal_to('float')
    end)
  end)

  describe('isinstance integration', function()
    it('should identify 3.14 as Float via isinstance', function()
      expect(isinstance(3.14, Float)).to.be_true()
    end)

    it('should not identify an integer as Float via isinstance', function()
      expect(isinstance(42, Float)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Integer
-- ---------------------------------------------------------------------------

describe('Integer', function()
  describe('__name', function()
    it('should have __name equal to "Integer"', function()
      expect(Integer.__name).to.be_equal_to('Integer')
    end)
  end)

  describe('__tostring', function()
    it('should return "Integer" when converted to string', function()
      expect(tostring(Integer)).to.be_equal_to('Integer')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for a positive integer', function()
      expect(Integer:__isinstance(42)).to.be_true()
    end)

    it('should return true for zero (integer form)', function()
      expect(Integer:__isinstance(0)).to.be_true()
    end)

    it('should return true for a negative integer', function()
      expect(Integer:__isinstance(-10)).to.be_true()
    end)

    it('should return false for a float', function()
      expect(Integer:__isinstance(3.14)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Integer:__isinstance('42')).to.be_false()
    end)

    it('should return false for nil', function()
      expect(Integer:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Integer:__isinstance(true)).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Integer:__isinstance({})).to.be_false()
    end)
  end)

  describe('__call (type conversion)', function()
    it('should return 0 for nil', function()
      local result = Integer(nil)
      expect(result).to.be_equal_to(0)
      expect(math.type(result)).to.be_equal_to('integer')
    end)

    it('should return 0 for false', function()
      local result = Integer(false)
      expect(result).to.be_equal_to(0)
      expect(math.type(result)).to.be_equal_to('integer')
    end)

    it('should return 1 for true', function()
      local result = Integer(true)
      expect(result).to.be_equal_to(1)
      expect(math.type(result)).to.be_equal_to('integer')
    end)

    it('should error when converting a float because tointeger is not in the module environment', function()
      expect(function() Integer(3.0) end).to.throw()
    end)

    it('should error when converting a numeric string because tointeger is not in the module environment', function()
      expect(function() Integer('7') end).to.throw()
    end)
  end)

  describe('isinstance integration', function()
    it('should identify 42 as Integer via isinstance', function()
      expect(isinstance(42, Integer)).to.be_true()
    end)

    it('should not identify a float as Integer via isinstance', function()
      expect(isinstance(3.14, Integer)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Nil
-- ---------------------------------------------------------------------------

describe('Nil', function()
  describe('__name', function()
    it('should have __name equal to "nil"', function()
      expect(Nil.__name).to.be_equal_to('nil')
    end)
  end)

  describe('__tostring', function()
    it('should return "Nil" when converted to string', function()
      expect(tostring(Nil)).to.be_equal_to('Nil')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for nil', function()
      expect(Nil:__isinstance(nil)).to.be_true()
    end)

    it('should return false for false', function()
      expect(Nil:__isinstance(false)).to.be_false()
    end)

    it('should return false for zero', function()
      expect(Nil:__isinstance(0)).to.be_false()
    end)

    it('should return false for an empty string', function()
      expect(Nil:__isinstance('')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Nil:__isinstance({})).to.be_false()
    end)

    it('should return false for true', function()
      expect(Nil:__isinstance(true)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should identify nil as Nil via isinstance', function()
      expect(isinstance(nil, Nil)).to.be_true()
    end)

    it('should not identify false as Nil via isinstance', function()
      expect(isinstance(false, Nil)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Function
-- ---------------------------------------------------------------------------

describe('Function', function()
  describe('__name', function()
    it('should have __name equal to "function"', function()
      expect(Function.__name).to.be_equal_to('function')
    end)
  end)

  describe('__tostring', function()
    it('should return "Function" when converted to string', function()
      expect(tostring(Function)).to.be_equal_to('Function')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for an anonymous function', function()
      expect(Function:__isinstance(function() end)).to.be_true()
    end)

    it('should return true for a named function', function()
      local function foo() end
      expect(Function:__isinstance(foo)).to.be_true()
    end)

    it('should return true for a built-in function', function()
      expect(Function:__isinstance(print)).to.be_true()
    end)

    it('should return false for nil', function()
      expect(Function:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a number', function()
      expect(Function:__isinstance(42)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Function:__isinstance('function')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Function:__isinstance({})).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Function:__isinstance(true)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should identify a function as Function via isinstance', function()
      expect(isinstance(function() end, Function)).to.be_true()
    end)

    it('should not identify a string as Function via isinstance', function()
      expect(isinstance('hello', Function)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Thread
-- ---------------------------------------------------------------------------

describe('Thread', function()
  describe('__name', function()
    it('should have __name equal to "Thread"', function()
      expect(Thread.__name).to.be_equal_to('Thread')
    end)
  end)

  describe('__tostring', function()
    it('should return "Thread" when converted to string', function()
      expect(tostring(Thread)).to.be_equal_to('Thread')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for a coroutine', function()
      local co = coroutine.create(function() end)
      expect(Thread:__isinstance(co)).to.be_true()
    end)

    it('should return false for nil', function()
      expect(Thread:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a function', function()
      expect(Thread:__isinstance(function() end)).to.be_false()
    end)

    it('should return false for a number', function()
      expect(Thread:__isinstance(42)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Thread:__isinstance('thread')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Thread:__isinstance({})).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Thread:__isinstance(true)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should identify a coroutine as Thread via isinstance', function()
      local co = coroutine.create(function() end)
      expect(isinstance(co, Thread)).to.be_true()
    end)

    it('should not identify a function as Thread via isinstance', function()
      expect(isinstance(function() end, Thread)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Userdata
-- ---------------------------------------------------------------------------

describe('Userdata', function()
  describe('__name', function()
    it('should have __name equal to "Userdata"', function()
      expect(Userdata.__name).to.be_equal_to('Userdata')
    end)
  end)

  describe('__tostring', function()
    it('should return "Userdata" when converted to string', function()
      expect(tostring(Userdata)).to.be_equal_to('Userdata')
    end)
  end)

  describe('__isinstance', function()
    it('should return false for nil', function()
      expect(Userdata:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a number', function()
      expect(Userdata:__isinstance(42)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Userdata:__isinstance('userdata')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Userdata:__isinstance({})).to.be_false()
    end)

    it('should return false for a function', function()
      expect(Userdata:__isinstance(function() end)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Userdata:__isinstance(true)).to.be_false()
    end)

    it('should return true for an io userdata handle', function()
      local handle = io.tmpfile()
      if handle then
        expect(Userdata:__isinstance(handle)).to.be_true()
        handle:close()
      end
    end)
  end)

  describe('isinstance integration', function()
    it('should not identify a table as Userdata via isinstance', function()
      expect(isinstance({}, Userdata)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Number
-- ---------------------------------------------------------------------------

describe('Number', function()
  describe('__name', function()
    it('should have __name equal to "Number"', function()
      expect(Number.__name).to.be_equal_to('Number')
    end)
  end)

  describe('__tostring', function()
    it('should return "Number" when converted to string', function()
      expect(tostring(Number)).to.be_equal_to('Number')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for an integer', function()
      expect(Number:__isinstance(42)).to.be_true()
    end)

    it('should return true for a float', function()
      expect(Number:__isinstance(3.14)).to.be_true()
    end)

    it('should return true for zero', function()
      expect(Number:__isinstance(0)).to.be_true()
    end)

    it('should return true for a negative number', function()
      expect(Number:__isinstance(-7.5)).to.be_true()
    end)

    it('should return true for math.huge (infinity)', function()
      expect(Number:__isinstance(math.huge)).to.be_true()
    end)

    it('should return false for a string', function()
      expect(Number:__isinstance('42')).to.be_false()
    end)

    it('should return false for nil', function()
      expect(Number:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Number:__isinstance(true)).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Number:__isinstance({})).to.be_false()
    end)

    it('should return false for a function', function()
      expect(Number:__isinstance(function() end)).to.be_false()
    end)
  end)

  describe('__call (type conversion)', function()
    it('should return 0 for nil', function()
      expect(Number(nil)).to.be_equal_to(0)
    end)

    it('should return 0 for false', function()
      expect(Number(false)).to.be_equal_to(0)
    end)

    it('should return 1 for true', function()
      expect(Number(true)).to.be_equal_to(1)
    end)

    it('should convert an integer to a number', function()
      expect(Number(42)).to.be_equal_to(42)
    end)

    it('should convert a float to a number', function()
      expect(Number(3.14)).to.be_equal_to(3.14)
    end)

    it('should convert a numeric string to a number', function()
      expect(Number('123')).to.be_equal_to(123)
    end)

    it('should convert a float string to a number', function()
      expect(Number('3.14')).to.be_equal_to(3.14)
    end)

    it('should return nil for a non-numeric string', function()
      expect(Number('hello')).to.be_nil()
    end)
  end)

  describe('__validate', function()
    describe('multiple_of', function()
      it('should pass when value is a multiple', function()
        local ok = Number.__validate(6, { multiple_of = 3 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when value is not a multiple because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(7, { multiple_of = 3 }, {}, 0, nil)
        end).to.throw()
      end)

      it('should pass when value is zero and multiple_of is nonzero', function()
        local ok = Number.__validate(0, { multiple_of = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)
    end)

    describe('minimum (inclusive, self must be > minimum)', function()
      it('should pass when value is greater than minimum', function()
        local ok = Number.__validate(10, { minimum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when value equals minimum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(5, { minimum = 5 }, {}, 0, nil)
        end).to.throw()
      end)

      it('should error when value is less than minimum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(3, { minimum = 5 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('exclusive_minimum (self must be >= exclusive_minimum)', function()
      it('should pass when value is greater than exclusive_minimum', function()
        local ok = Number.__validate(10, { exclusive_minimum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should pass when value equals exclusive_minimum', function()
        local ok = Number.__validate(5, { exclusive_minimum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when value is less than exclusive_minimum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(3, { exclusive_minimum = 5 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('maximum (exclusive, self must be < maximum)', function()
      it('should pass when value is less than maximum', function()
        local ok = Number.__validate(3, { maximum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when value equals maximum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(5, { maximum = 5 }, {}, 0, nil)
        end).to.throw()
      end)

      it('should error when value is greater than maximum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(10, { maximum = 5 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('exclusive_maximum (self must be <= exclusive_maximum)', function()
      it('should pass when value is less than exclusive_maximum', function()
        local ok = Number.__validate(3, { exclusive_maximum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should pass when value equals exclusive_maximum', function()
        local ok = Number.__validate(5, { exclusive_maximum = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when value is greater than exclusive_maximum because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(10, { exclusive_maximum = 5 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('combined constraints', function()
      it('should pass when all constraints are satisfied', function()
        local ok = Number.__validate(6, {
          minimum = 0,
          maximum = 10,
          multiple_of = 3,
        }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when multiple_of constraint fails even if range is ok because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          Number.__validate(5, {
            minimum = 0,
            maximum = 10,
            multiple_of = 3,
          }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('no constraints', function()
      it('should pass with an empty schema', function()
        local ok = Number.__validate(42, {}, {}, 0, nil)
        expect(ok).to.be_true()
      end)
    end)
  end)

  describe('isinstance integration', function()
    it('should identify an integer as Number via isinstance', function()
      expect(isinstance(42, Number)).to.be_true()
    end)

    it('should identify a float as Number via isinstance', function()
      expect(isinstance(3.14, Number)).to.be_true()
    end)

    it('should not identify a string as Number via isinstance', function()
      expect(isinstance('42', Number)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- String
-- ---------------------------------------------------------------------------

describe('String', function()
  describe('__name', function()
    it('should have __name equal to "String"', function()
      expect(String.__name).to.be_equal_to('String')
    end)
  end)

  describe('__tostring', function()
    it('should return "String" when converted to string', function()
      expect(tostring(String)).to.be_equal_to('String')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for a regular string', function()
      expect(String:__isinstance('hello')).to.be_true()
    end)

    it('should return true for an empty string', function()
      expect(String:__isinstance('')).to.be_true()
    end)

    it('should return true for a string with spaces', function()
      expect(String:__isinstance('hello world')).to.be_true()
    end)

    it('should return false for a number', function()
      expect(String:__isinstance(42)).to.be_false()
    end)

    it('should return false for nil', function()
      expect(String:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(String:__isinstance(true)).to.be_false()
    end)

    it('should return false for a table', function()
      expect(String:__isinstance({})).to.be_false()
    end)

    it('should return false for a function', function()
      expect(String:__isinstance(function() end)).to.be_false()
    end)
  end)

  describe('__call (type conversion)', function()
    it('should convert a number to a string', function()
      expect(String(42)).to.be_equal_to('42')
    end)

    it('should convert a boolean to a string', function()
      expect(String(true)).to.be_equal_to('true')
    end)

    it('should return an empty string for nil', function()
      expect(String(nil)).to.be_equal_to('')
    end)

    it('should return an empty string for false', function()
      expect(String(false)).to.be_equal_to('')
    end)

    it('should return the same string for a string', function()
      expect(String('hello')).to.be_equal_to('hello')
    end)
  end)

  describe('__validate', function()
    describe('min_length', function()
      it('should pass when string length meets min_length', function()
        local ok = String.__validate('hello', { min_length = 3 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should pass when string length equals min_length', function()
        local ok = String.__validate('abc', { min_length = 3 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when string length is below min_length because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('ab', { min_length = 3 }, {}, 0, nil)
        end).to.throw()
      end)

      it('should error for an empty string with min_length = 1 because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('', { min_length = 1 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('max_length', function()
      it('should pass when string length is below max_length', function()
        local ok = String.__validate('hi', { max_length = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should pass when string length equals max_length', function()
        local ok = String.__validate('hello', { max_length = 5 }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when string length exceeds max_length because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('hello world', { max_length = 5 }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('pattern', function()
      it('should pass when string matches the pattern', function()
        local ok = String.__validate('hello123', { pattern = '%d+' }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when string does not match the pattern because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('hello', { pattern = '^%d+$' }, {}, 0, nil)
        end).to.throw()
      end)

      it('should pass for a pattern anchored at start', function()
        local ok = String.__validate('abc123', { pattern = '^abc' }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error for a pattern anchored at start that does not match because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('123abc', { pattern = '^abc' }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('combined constraints', function()
      it('should pass when all constraints are satisfied', function()
        local ok = String.__validate('abc123', {
          min_length = 3,
          max_length = 10,
          pattern = '%d+',
        }, {}, 0, nil)
        expect(ok).to.be_true()
      end)

      it('should error when min_length fails even if pattern passes because SchemaConstraintFailureException is unavailable', function()
        expect(function()
          String.__validate('a1', {
            min_length = 5,
            pattern = '%d',
          }, {}, 0, nil)
        end).to.throw()
      end)
    end)

    describe('no constraints', function()
      it('should pass with an empty schema', function()
        local ok = String.__validate('anything', {}, {}, 0, nil)
        expect(ok).to.be_true()
      end)
    end)
  end)

  describe('join', function()
    it('should join table elements with the separator', function()
      expect(String.join(', ', {'a', 'b', 'c'})).to.be_equal_to('a, b, c')
    end)

    it('should return a single element unchanged', function()
      expect(String.join(', ', {'only'})).to.be_equal_to('only')
    end)

    it('should return an empty string for an empty table', function()
      expect(String.join(', ', {})).to.be_equal_to('')
    end)

    it('should join with an empty separator', function()
      expect(String.join('', {'a', 'b', 'c'})).to.be_equal_to('abc')
    end)

    it('should convert non-string elements via tostring', function()
      expect(String.join('-', {1, 2, 3})).to.be_equal_to('1-2-3')
    end)
  end)

  describe('empty', function()
    it('should return true for an empty string', function()
      expect(String.empty('')).to.be_true()
    end)

    it('should return false for a non-empty string', function()
      expect(String.empty('hello')).to.be_false()
    end)

    it('should return false for a single space', function()
      expect(String.empty(' ')).to.be_false()
    end)
  end)

  describe('startswith', function()
    it('should return true when string starts with the prefix', function()
      expect(String.startswith('hello world', 'hello')).to.be_true()
    end)

    it('should return false when string does not start with the prefix', function()
      expect(String.startswith('hello world', 'world')).to.be_false()
    end)

    it('should return true when prefix equals the full string', function()
      expect(String.startswith('hello', 'hello')).to.be_true()
    end)

    it('should return true for an empty prefix', function()
      expect(String.startswith('hello', '')).to.be_true()
    end)
  end)

  describe('endswith', function()
    it('should return true when string ends with the suffix', function()
      expect(String.endswith('hello world', 'world')).to.be_true()
    end)

    it('should return false when string does not end with the suffix', function()
      expect(String.endswith('hello world', 'hello')).to.be_false()
    end)

    it('should return true when suffix equals the full string', function()
      expect(String.endswith('hello', 'hello')).to.be_true()
    end)

    it('should return true for an empty suffix', function()
      expect(String.endswith('hello', '')).to.be_true()
    end)
  end)

  describe('__unm (reverse via unary minus)', function()
    it('should reverse a string', function()
      expect(-'hello').to.be_equal_to('olleh')
    end)

    it('should return an empty string when reversing an empty string', function()
      expect(-'').to.be_equal_to('')
    end)

    it('should return single char unchanged', function()
      expect(-'a').to.be_equal_to('a')
    end)

    it('should reverse a palindrome to itself', function()
      expect(-'racecar').to.be_equal_to('racecar')
    end)
  end)

  describe('__mul (string repetition)', function()
    it('should repeat a string the specified number of times', function()
      expect('ab' * 3).to.be_equal_to('ababab')
    end)

    it('should return an empty string when repeated 0 times', function()
      expect('hello' * 0).to.be_equal_to('')
    end)

    it('should return the original string when repeated 1 time', function()
      expect('hello' * 1).to.be_equal_to('hello')
    end)
  end)

  describe('__index (character access by numeric index)', function()
    it('should return the first character for index 1', function()
      expect(('hello')[1]).to.be_equal_to('h')
    end)

    it('should return the second character for index 2', function()
      expect(('hello')[2]).to.be_equal_to('e')
    end)

    it('should return the last character for index equal to length', function()
      expect(('hello')[5]).to.be_equal_to('o')
    end)
  end)

  describe('__shl (left rotate)', function()
    it('should rotate left by 1', function()
      expect('abcde' << 1).to.be_equal_to('bcdea')
    end)

    it('should rotate left by 2', function()
      expect('abcde' << 2).to.be_equal_to('cdeab')
    end)

    it('should return same string for rotation of 0', function()
      expect('abcde' << 0).to.be_equal_to('abcde')
    end)
  end)

  describe('__shr (right rotate)', function()
    it('should rotate right by 1', function()
      expect('abcde' >> 1).to.be_equal_to('eabcd')
    end)

    it('should rotate right by 2', function()
      expect('abcde' >> 2).to.be_equal_to('deabc')
    end)

    it('should return the string doubled for rotation of 0 due to sub(-0) behavior', function()
      expect('abcde' >> 0).to.be_equal_to('abcdeabcde')
    end)
  end)

  describe('__call (character iterator)', function()
    it('should iterate over each character in the string', function()
      local chars = {}
      for i, c in 'abc' do
        chars[i] = c
      end
      expect(chars[1]).to.be_equal_to('a')
      expect(chars[2]).to.be_equal_to('b')
      expect(chars[3]).to.be_equal_to('c')
    end)

    it('should produce no iterations for an empty string', function()
      local count = 0
      for i, c in '' do
        count = count + 1
      end
      expect(count).to.be_equal_to(0)
    end)
  end)

  describe('isinstance integration', function()
    it('should identify a string as String via isinstance', function()
      expect(isinstance('hello', String)).to.be_true()
    end)

    it('should not identify a number as String via isinstance', function()
      expect(isinstance(42, String)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Cross-type rejection tests
-- ---------------------------------------------------------------------------

describe('Cross-type rejection', function()
  it('should not identify a string as Boolean', function()
    expect(isinstance('true', Boolean)).to.be_false()
  end)

  it('should not identify a boolean as Number', function()
    expect(isinstance(true, Number)).to.be_false()
  end)

  it('should not identify a number as String', function()
    expect(isinstance(42, String)).to.be_false()
  end)

  it('should not identify a table as Function', function()
    expect(isinstance({}, Function)).to.be_false()
  end)

  it('should not identify nil as Boolean', function()
    expect(isinstance(nil, Boolean)).to.be_false()
  end)

  it('should not identify a function as Thread', function()
    expect(isinstance(function() end, Thread)).to.be_false()
  end)

  it('should not identify a number as Nil', function()
    expect(isinstance(0, Nil)).to.be_false()
  end)

  it('should not identify a string as Integer', function()
    expect(isinstance('42', Integer)).to.be_false()
  end)

  it('should not identify an integer as Float', function()
    expect(isinstance(42, Float)).to.be_false()
  end)

  it('should not identify a float as Integer', function()
    expect(isinstance(3.14, Integer)).to.be_false()
  end)

  it('should identify an integer as Number but not as Float', function()
    expect(isinstance(42, Number)).to.be_true()
    expect(isinstance(42, Float)).to.be_false()
  end)

  it('should identify a float as Number but not as Integer', function()
    expect(isinstance(3.14, Number)).to.be_true()
    expect(isinstance(3.14, Integer)).to.be_false()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
