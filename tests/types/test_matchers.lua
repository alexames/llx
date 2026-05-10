local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'

local Any = matchers.Any
local Union = matchers.Union
local Optional = matchers.Optional
local Dict = matchers.Dict

local Integer = llx.Integer
local Number = llx.Number
local String = llx.String
local Nil = llx.Nil
local isinstance = llx.isinstance

_ENV = unit.create_test_env(_ENV)

-- ---------------------------------------------------------------------------
-- Any
-- ---------------------------------------------------------------------------

describe('Any', function()
  describe('__name', function()
    it('should have __name equal to "Any"', function()
      expect(Any.__name).to.be_equal_to('Any')
    end)
  end)

  describe('__isinstance', function()
    it('should return true for nil', function()
      expect(Any:__isinstance(nil)).to.be_true()
    end)

    it('should return true for a boolean', function()
      expect(Any:__isinstance(true)).to.be_true()
    end)

    it('should return true for false', function()
      expect(Any:__isinstance(false)).to.be_true()
    end)

    it('should return true for a number (integer)', function()
      expect(Any:__isinstance(42)).to.be_true()
    end)

    it('should return true for a number (float)', function()
      expect(Any:__isinstance(3.14)).to.be_true()
    end)

    it('should return true for a string', function()
      expect(Any:__isinstance('hello')).to.be_true()
    end)

    it('should return true for a table', function()
      expect(Any:__isinstance({})).to.be_true()
    end)

    it('should return true for a function', function()
      expect(Any:__isinstance(function() end)).to.be_true()
    end)
  end)

  describe('isinstance integration', function()
    it('should match nil via isinstance', function()
      expect(isinstance(nil, Any)).to.be_true()
    end)

    it('should match a boolean via isinstance', function()
      expect(isinstance(true, Any)).to.be_true()
    end)

    it('should match a number via isinstance', function()
      expect(isinstance(42, Any)).to.be_true()
    end)

    it('should match a string via isinstance', function()
      expect(isinstance('hello', Any)).to.be_true()
    end)

    it('should match a table via isinstance', function()
      expect(isinstance({}, Any)).to.be_true()
    end)

    it('should match a function via isinstance', function()
      expect(isinstance(function() end, Any)).to.be_true()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Union
-- ---------------------------------------------------------------------------

describe('Union', function()
  describe('__isinstance', function()
    it('should return true when value matches the first '
      .. 'type in the list', function()
      local StringOrNumber = Union{String, Number}
      expect(StringOrNumber:__isinstance('hello')).to.be_true()
    end)

    it('should return true when value matches the second '
      .. 'type in the list', function()
      local StringOrNumber = Union{String, Number}
      expect(StringOrNumber:__isinstance(42)).to.be_true()
    end)

    it('should return false when value matches none of the types', function()
      local StringOrNumber = Union{String, Number}
      expect(StringOrNumber:__isinstance(true)).to.be_false()
    end)

    it('should return false for nil when nil is not in the union', function()
      local StringOrNumber = Union{String, Number}
      expect(StringOrNumber:__isinstance(nil)).to.be_false()
    end)

    it('should return true for nil when Nil is in the union', function()
      local NilOrString = Union{Nil, String}
      expect(NilOrString:__isinstance(nil)).to.be_true()
    end)

    it('should handle a single type in the union', function()
      local OnlyString = Union{String}
      expect(OnlyString:__isinstance('hello')).to.be_true()
      expect(OnlyString:__isinstance(42)).to.be_false()
    end)

    it('should handle multiple types with integer and string', function()
      local IntOrString = Union{Integer, String}
      expect(IntOrString:__isinstance(42)).to.be_true()
      expect(IntOrString:__isinstance('hello')).to.be_true()
      expect(IntOrString:__isinstance(true)).to.be_false()
      expect(IntOrString:__isinstance(3.14)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should match a string via isinstance for '
      .. 'Union{String, Number}', function()
      local StringOrNumber = Union{String, Number}
      expect(isinstance('hello', StringOrNumber)).to.be_true()
    end)

    it('should match a number via isinstance for '
      .. 'Union{String, Number}', function()
      local StringOrNumber = Union{String, Number}
      expect(isinstance(42, StringOrNumber)).to.be_true()
    end)

    it('should not match a boolean via isinstance for '
      .. 'Union{String, Number}', function()
      local StringOrNumber = Union{String, Number}
      expect(isinstance(true, StringOrNumber)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Optional
-- ---------------------------------------------------------------------------

describe('Optional', function()
  describe('Optional(Type) natural form', function()
    it('should return true for nil', function()
      local OptString = Optional(String)
      expect(OptString:__isinstance(nil)).to.be_true()
    end)

    it('should return true for a value matching the given type', function()
      local OptString = Optional(String)
      expect(OptString:__isinstance('hello')).to.be_true()
    end)

    it('should return false for a value of the wrong type', function()
      local OptInt = Optional(Integer)
      expect(OptInt:__isinstance('hello')).to.be_false()
    end)

    it('should accept matching integers when wrapping Integer', function()
      local OptInt = Optional(Integer)
      expect(OptInt:__isinstance(42)).to.be_true()
    end)
  end)

  describe('__isinstance (list-wrapped form)', function()
    it('should return true for nil', function()
      local OptString = Optional{String}
      expect(OptString:__isinstance(nil)).to.be_true()
    end)

    it('should return true for a value matching the given type', function()
      local OptString = Optional{String}
      expect(OptString:__isinstance('hello')).to.be_true()
    end)

    it('should return false for a value not matching the given type', function()
      local OptString = Optional{String}
      expect(OptString:__isinstance(42)).to.be_false()
    end)

    it('should return true for nil with Optional Number', function()
      local OptNumber = Optional{Number}
      expect(OptNumber:__isinstance(nil)).to.be_true()
    end)

    it('should return true for a number with Optional Number', function()
      local OptNumber = Optional{Number}
      expect(OptNumber:__isinstance(42)).to.be_true()
    end)

    it('should return false for a string with Optional Number', function()
      local OptNumber = Optional{Number}
      expect(OptNumber:__isinstance('hello')).to.be_false()
    end)

    it('should return true for nil with Optional Integer', function()
      local OptInt = Optional{Integer}
      expect(OptInt:__isinstance(nil)).to.be_true()
    end)

    it('should return true for an integer with Optional Integer', function()
      local OptInt = Optional{Integer}
      expect(OptInt:__isinstance(42)).to.be_true()
    end)

    it('should return false for a string with Optional Integer', function()
      local OptInt = Optional{Integer}
      expect(OptInt:__isinstance('hello')).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should match nil via isinstance for Optional String', function()
      local OptString = Optional{String}
      expect(isinstance(nil, OptString)).to.be_true()
    end)

    it('should match a string via isinstance for Optional String', function()
      local OptString = Optional{String}
      expect(isinstance('hello', OptString)).to.be_true()
    end)

    it('should not match a number via isinstance for '
      .. 'Optional String', function()
      local OptString = Optional{String}
      expect(isinstance(42, OptString)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Dict
-- ---------------------------------------------------------------------------

describe('Dict', function()
  describe('__isinstance', function()
    it('should accept a table with matching key and value types', function()
      local D = Dict(String, Integer)
      expect(D:__isinstance({a = 1, b = 2})).to.be_true()
    end)

    it('should accept an empty table', function()
      local D = Dict(String, Integer)
      expect(D:__isinstance({})).to.be_true()
    end)

    it('should reject a value with a wrong-typed key', function()
      local D = Dict(String, Integer)
      expect(D:__isinstance({[1] = 1})).to.be_false()
    end)

    it('should reject a value with a wrong-typed value', function()
      local D = Dict(String, Integer)
      expect(D:__isinstance({a = 'x'})).to.be_false()
    end)

    it('should reject a non-table value', function()
      local D = Dict(String, Integer)
      expect(D:__isinstance(42)).to.be_false()
      expect(D:__isinstance('x')).to.be_false()
      expect(D:__isinstance(nil)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should match via isinstance', function()
      local D = Dict(String, Number)
      expect(isinstance({a = 1.5, b = 2}, D)).to.be_true()
      expect(isinstance({a = 'x'}, D)).to.be_false()
    end)
  end)

  describe('__name', function()
    it('should expose a Dict<K, V> name', function()
      local D = Dict(String, Integer)
      expect(D.__name:find('Dict')).to_not.be_nil()
      expect(D.__name:find('String')).to_not.be_nil()
      expect(D.__name:find('Integer')).to_not.be_nil()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
