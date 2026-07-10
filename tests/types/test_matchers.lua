local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'
local signature = require 'llx.signature'

local Any = matchers.Any
local Never = matchers.Never
local Union = matchers.Union
local Optional = matchers.Optional
local Dict = matchers.Dict
local ListOf = matchers.ListOf
local SetOf = matchers.SetOf
local Protocol = matchers.Protocol
local Callable = matchers.Callable
local Tuple = matchers.Tuple
local Literal = matchers.Literal
local ClassOf = matchers.ClassOf
local Rest = matchers.Rest
local Lazy = matchers.Lazy
local resolve_lazy = matchers.resolve_lazy
local Iterator = matchers.Iterator
local Generator = matchers.Generator

local TupleValue = require 'llx.tuple' . Tuple
local VARARG = require 'llx.check_arguments' . VARARG

local Integer = llx.Integer
local Number = llx.Number
local String = llx.String
local Boolean = llx.Boolean
local Nil = llx.Nil
local isinstance = llx.isinstance
local is_subtype = llx.is_subtype
local Schema = llx.Schema
local Table = llx.Table

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
-- Never
-- ---------------------------------------------------------------------------

describe('Never', function()
  describe('__name', function()
    it('should have __name equal to "Never"', function()
      expect(Never.__name).to.be_equal_to('Never')
    end)
  end)

  describe('__tostring', function()
    it('should stringify as "Never"', function()
      expect(tostring(Never)).to.be_equal_to('Never')
    end)
  end)

  describe('__isinstance', function()
    it('should return false for nil', function()
      expect(Never:__isinstance(nil)).to.be_false()
    end)

    it('should return false for a boolean', function()
      expect(Never:__isinstance(true)).to.be_false()
    end)

    it('should return false for false', function()
      expect(Never:__isinstance(false)).to.be_false()
    end)

    it('should return false for a number (integer)', function()
      expect(Never:__isinstance(42)).to.be_false()
    end)

    it('should return false for a number (float)', function()
      expect(Never:__isinstance(3.14)).to.be_false()
    end)

    it('should return false for a string', function()
      expect(Never:__isinstance('hello')).to.be_false()
    end)

    it('should return false for a table', function()
      expect(Never:__isinstance({})).to.be_false()
    end)

    it('should return false for a function', function()
      expect(Never:__isinstance(function() end)).to.be_false()
    end)

    it('should return false for a coroutine', function()
      expect(Never:__isinstance(coroutine.create(function() end)))
        .to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should not match nil via isinstance', function()
      expect(isinstance(nil, Never)).to.be_false()
    end)

    it('should not match a boolean via isinstance', function()
      expect(isinstance(true, Never)).to.be_false()
    end)

    it('should not match a number via isinstance', function()
      expect(isinstance(42, Never)).to.be_false()
    end)

    it('should not match a string via isinstance', function()
      expect(isinstance('hello', Never)).to.be_false()
    end)

    it('should not match a table via isinstance', function()
      expect(isinstance({}, Never)).to.be_false()
    end)

    it('should not match a function via isinstance', function()
      expect(isinstance(function() end, Never)).to.be_false()
    end)
  end)

  describe('Union composition', function()
    it('should act as an identity element: Union{Never, Integer} '
      .. 'accepts integers', function()
      local NeverOrInteger = Union{Never, Integer}
      expect(isinstance(42, NeverOrInteger)).to.be_true()
    end)

    it('should act as an identity element: Union{Never, Integer} '
      .. 'rejects non-integers', function()
      local NeverOrInteger = Union{Never, Integer}
      expect(isinstance('hello', NeverOrInteger)).to.be_false()
      expect(isinstance(3.14, NeverOrInteger)).to.be_false()
      expect(isinstance(nil, NeverOrInteger)).to.be_false()
    end)

    it('should make Union{Never} match nothing', function()
      local Bottom = Union{Never}
      expect(isinstance(nil, Bottom)).to.be_false()
      expect(isinstance(42, Bottom)).to.be_false()
      expect(isinstance('hello', Bottom)).to.be_false()
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

-- ---------------------------------------------------------------------------
-- ListOf
-- ---------------------------------------------------------------------------

describe('ListOf', function()
  describe('__name', function()
    it('should expose a ListOf<T> name', function()
      local L = ListOf(Integer)
      expect(L.__name).to.be_equal_to('ListOf<Integer>')
    end)

    it('should be used as the tostring form', function()
      local L = ListOf(String)
      expect(tostring(L)).to.be_equal_to('ListOf<String>')
    end)
  end)

  describe('element_type field', function()
    it('should expose the element type', function()
      local L = ListOf(Integer)
      expect(L.element_type).to.be_equal_to(Integer)
    end)
  end)

  describe('__isinstance on plain tables', function()
    it('should accept an empty table', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({})).to.be_true()
    end)

    it('should accept a homogeneous array', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({1, 2, 3})).to.be_true()
    end)

    it('should reject an array with a single bad element', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({1, 'two', 3})).to.be_false()
    end)

    it('should reject an array whose last element is bad', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({1, 2, 3.5})).to.be_false()
    end)

    it('should reject non-table values', function()
      local L = ListOf(Integer)
      expect(L:__isinstance(42)).to.be_false()
      expect(L:__isinstance('x')).to.be_false()
      expect(L:__isinstance(nil)).to.be_false()
      expect(L:__isinstance(true)).to.be_false()
    end)

    it('should reject a hash-only table (no vacuous match over an '
      .. 'empty array part)', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({meta = print})).to.be_false()
      expect(L:__isinstance({a = 1, b = 2})).to.be_false()
    end)

    it('should reject a table with hash keys alongside the array '
      .. 'part', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({1, 2, extra = 'nope'})).to.be_false()
      expect(L:__isinstance({1, 2, [4.5] = 3})).to.be_false()
    end)

    it('should reject a table with a hole (keys beyond the ipairs '
      .. 'prefix)', function()
      local L = ListOf(Integer)
      expect(L:__isinstance({1, 2, nil, 4})).to.be_false()
      expect(L:__isinstance({[2] = 1})).to.be_false()
      expect(L:__isinstance({[0] = 1, [1] = 2})).to.be_false()
    end)
  end)

  describe('__isinstance on llx.List values', function()
    it('should accept a homogeneous List instance', function()
      local L = ListOf(Integer)
      expect(L:__isinstance(llx.List{1, 2, 3})).to.be_true()
    end)

    it('should accept an empty List instance', function()
      local L = ListOf(Integer)
      expect(L:__isinstance(llx.List{})).to.be_true()
    end)

    it('should reject a List instance with a bad element', function()
      local L = ListOf(Integer)
      expect(L:__isinstance(llx.List{1, 'two'})).to.be_false()
    end)
  end)

  describe('nested composition', function()
    it('should compose as ListOf(ListOf(Integer))', function()
      local L = ListOf(ListOf(Integer))
      expect(L:__isinstance({{1, 2}, {3}})).to.be_true()
      expect(L:__isinstance({{1, 2}, {'x'}})).to.be_false()
      expect(L:__isinstance({{}, {}})).to.be_true()
    end)

    it('should compose as Dict(String, ListOf(Number))', function()
      local D = Dict(String, ListOf(Number))
      expect(D:__isinstance({a = {1, 2.5}, b = {}})).to.be_true()
      expect(D:__isinstance({a = {1, 'x'}})).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local L = ListOf(String)
      expect(isinstance({'a', 'b'}, L)).to.be_true()
      expect(isinstance({'a', 1}, L)).to.be_false()
      expect(isinstance('not a table', L)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- SetOf
-- ---------------------------------------------------------------------------

describe('SetOf', function()
  describe('__name', function()
    it('should expose a SetOf<T> name', function()
      local S = SetOf(Integer)
      expect(S.__name).to.be_equal_to('SetOf<Integer>')
    end)

    it('should be used as the tostring form', function()
      local S = SetOf(String)
      expect(tostring(S)).to.be_equal_to('SetOf<String>')
    end)
  end)

  describe('element_type field', function()
    it('should expose the element type', function()
      local S = SetOf(String)
      expect(S.element_type).to.be_equal_to(String)
    end)
  end)

  describe('__isinstance', function()
    it('should accept an empty Set', function()
      local S = SetOf(Integer)
      expect(S:__isinstance(llx.Set{})).to.be_true()
    end)

    it('should accept a homogeneous Set', function()
      local S = SetOf(Integer)
      expect(S:__isinstance(llx.Set{1, 2, 3})).to.be_true()
    end)

    it('should reject a Set with a single bad element', function()
      local S = SetOf(Integer)
      expect(S:__isinstance(llx.Set{1, 'two', 3})).to.be_false()
    end)

    it('should reject a plain table, even a set-shaped one', function()
      local S = SetOf(Integer)
      expect(S:__isinstance({[1] = true, [2] = true})).to.be_false()
      expect(S:__isinstance({})).to.be_false()
    end)

    it('should reject a hash-only table (the nominal Set guard '
      .. 'means no vacuous match; mirrors ListOf, #65)', function()
      local S = SetOf(Integer)
      expect(S:__isinstance({meta = print})).to.be_false()
      expect(isinstance({meta = print}, S)).to.be_false()
    end)

    it('should reject non-table values', function()
      local S = SetOf(Integer)
      expect(S:__isinstance(42)).to.be_false()
      expect(S:__isinstance('x')).to.be_false()
      expect(S:__isinstance(nil)).to.be_false()
      expect(S:__isinstance(true)).to.be_false()
    end)
  end)

  describe('nested composition', function()
    it('should compose as ListOf(SetOf(Integer))', function()
      local L = ListOf(SetOf(Integer))
      expect(L:__isinstance({llx.Set{1}, llx.Set{2, 3}})).to.be_true()
      expect(L:__isinstance({llx.Set{1}, llx.Set{'x'}})).to.be_false()
    end)

    it('should compose as Dict(String, SetOf(String))', function()
      local D = Dict(String, SetOf(String))
      expect(D:__isinstance({tags = llx.Set{'a', 'b'}})).to.be_true()
      expect(D:__isinstance({tags = llx.Set{1}})).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local S = SetOf(String)
      expect(isinstance(llx.Set{'a', 'b'}, S)).to.be_true()
      expect(isinstance(llx.Set{'a', 1}, S)).to.be_false()
      expect(isinstance({'a'}, S)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Tuple
-- ---------------------------------------------------------------------------

describe('Tuple', function()
  describe('__name', function()
    it('should expose a Tuple<...> name listing element types', function()
      local T = Tuple{Integer, String}
      expect(T.__name).to.be_equal_to('Tuple<Integer, String>')
    end)

    it('should handle an empty element type list', function()
      local T = Tuple{}
      expect(T.__name).to.be_equal_to('Tuple<>')
    end)

    it('should be used as the tostring form', function()
      local T = Tuple{Integer, String}
      expect(tostring(T)).to.be_equal_to('Tuple<Integer, String>')
    end)
  end)

  describe('element_types field', function()
    it('should expose the positional type list', function()
      local types = {Integer, String}
      local T = Tuple(types)
      expect(T.element_types).to.be_equal_to(types)
    end)
  end)

  describe('__isinstance on plain tables', function()
    it('should accept a table with the declared shape', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance({1, 'one'})).to.be_true()
    end)

    it('should reject a table that is too short', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance({1})).to.be_false()
    end)

    it('should reject a table that is too long', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance({1, 'one', 'extra'})).to.be_false()
    end)

    it('should reject a wrong-typed first element', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance({'one', 'two'})).to.be_false()
    end)

    it('should reject a wrong-typed second element', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance({1, 2})).to.be_false()
    end)

    it('should accept only the empty table for Tuple{}', function()
      local T = Tuple{}
      expect(T:__isinstance({})).to.be_true()
      expect(T:__isinstance({1})).to.be_false()
    end)

    it('should reject non-table values', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance(42)).to.be_false()
      expect(T:__isinstance('x')).to.be_false()
      expect(T:__isinstance(nil)).to.be_false()
      expect(T:__isinstance(true)).to.be_false()
    end)
  end)

  describe('__isinstance on llx.Tuple values', function()
    it('should accept a Tuple value with the declared shape', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance(TupleValue{1, 'one'})).to.be_true()
    end)

    it('should reject a Tuple value of the wrong length', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance(TupleValue{1})).to.be_false()
      expect(T:__isinstance(TupleValue{1, 'one', 2})).to.be_false()
    end)

    it('should reject a Tuple value with a wrong-typed '
      .. 'element', function()
      local T = Tuple{Integer, String}
      expect(T:__isinstance(TupleValue{1, 2})).to.be_false()
    end)

    it('should accept an empty Tuple value for Tuple{}', function()
      local T = Tuple{}
      expect(T:__isinstance(TupleValue{})).to.be_true()
    end)
  end)

  describe('nested Tuple matchers', function()
    it('should compose with another Tuple as an element type', function()
      local T = Tuple{Integer, Tuple{String, String}}
      expect(T:__isinstance({1, {'a', 'b'}})).to.be_true()
      expect(T:__isinstance({1, {'a', 2}})).to.be_false()
      expect(T:__isinstance({1, {'a'}})).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local T = Tuple{Integer, String}
      expect(isinstance({1, 'one'}, T)).to.be_true()
      expect(isinstance(TupleValue{1, 'one'}, T)).to.be_true()
      expect(isinstance({1, 2}, T)).to.be_false()
    end)
  end)

  describe('composition', function()
    it('should compose inside Union', function()
      local Pair = Tuple{Integer, Integer}
      local U = Union{String, Pair}
      expect(isinstance('hello', U)).to.be_true()
      expect(isinstance({1, 2}, U)).to.be_true()
      expect(isinstance({1, 'two'}, U)).to.be_false()
    end)

    it('should compose inside Protocol', function()
      local Shape = Protocol{
        name = String,
        position = Tuple{Number, Number},
      }
      expect(isinstance({
        name = 'origin',
        position = {0.0, 0.0},
      }, Shape)).to.be_true()
      expect(isinstance({
        name = 'broken',
        position = {0.0},
      }, Shape)).to.be_false()
    end)
  end)

  describe('variadic tails', function()
    describe('__name', function()
      it('should spell an unchecked tail as ...', function()
        local T = Tuple{String, Number, VARARG}
        expect(T.__name).to.be_equal_to('Tuple<String, Number, ...>')
      end)

      it('should spell a typed tail as ...T', function()
        local T = Tuple{String, Rest(Number)}
        expect(T.__name).to.be_equal_to('Tuple<String, ...Number>')
      end)

      it('should spell a prefixless typed tail as ...T', function()
        local T = Tuple{Rest(Integer)}
        expect(T.__name).to.be_equal_to('Tuple<...Integer>')
      end)

      it('should distinguish the two tail forms by name', function()
        local unchecked = Tuple{Integer, VARARG}
        local typed = Tuple{Integer, Rest(Integer)}
        expect(unchecked.__name == typed.__name).to.be_false()
      end)
    end)

    describe('unchecked tail (bare VARARG)', function()
      it('should accept an empty tail', function()
        local T = Tuple{Integer, String, VARARG}
        expect(T:__isinstance({1, 'one'})).to.be_true()
      end)

      it('should accept a long tail of arbitrary types', function()
        local T = Tuple{Integer, String, VARARG}
        expect(T:__isinstance({1, 'one', true, {}, 'x', 2.5}))
          .to.be_true()
      end)

      it('should still reject a value shorter than the '
        .. 'prefix', function()
        local T = Tuple{Integer, String, VARARG}
        expect(T:__isinstance({1})).to.be_false()
      end)

      it('should still type-check the fixed prefix', function()
        local T = Tuple{Integer, String, VARARG}
        expect(T:__isinstance({'one', 'two', 3})).to.be_false()
        expect(T:__isinstance({1, 2, 3})).to.be_false()
      end)

      it('should accept any sequence for Tuple{VARARG}', function()
        local T = Tuple{VARARG}
        expect(T:__isinstance({})).to.be_true()
        expect(T:__isinstance({1, 'mixed', true})).to.be_true()
        expect(T:__isinstance(42)).to.be_false()
      end)
    end)

    describe('typed tail (Rest)', function()
      it('should accept an empty tail', function()
        local T = Tuple{String, Rest(Number)}
        expect(T:__isinstance({'label'})).to.be_true()
      end)

      it('should accept a homogeneous typed tail', function()
        local T = Tuple{String, Rest(Number)}
        expect(T:__isinstance({'label', 1, 2.5, 3})).to.be_true()
      end)

      it('should reject a tail value of the wrong type', function()
        local T = Tuple{String, Rest(Number)}
        expect(T:__isinstance({'label', 1, 'oops'})).to.be_false()
        expect(T:__isinstance({'label', 1, 2, true})).to.be_false()
      end)

      it('should still type-check the fixed prefix', function()
        local T = Tuple{String, Rest(Number)}
        expect(T:__isinstance({1, 2, 3})).to.be_false()
      end)

      it('should still reject a value shorter than the '
        .. 'prefix', function()
        local T = Tuple{String, Rest(Number)}
        expect(T:__isinstance({})).to.be_false()
      end)

      it('should express tuple[T, ...] as Tuple{Rest(T)}', function()
        local Ints = Tuple{Rest(Integer)}
        expect(Ints:__isinstance({})).to.be_true()
        expect(Ints:__isinstance({1, 2, 3})).to.be_true()
        expect(Ints:__isinstance({1, 2.5})).to.be_false()
        expect(Ints:__isinstance({1, 'x'})).to.be_false()
      end)

      it('should compose matchers as the tail type', function()
        local T = Tuple{Rest(Union{Integer, String})}
        expect(T:__isinstance({1, 'a', 2})).to.be_true()
        expect(T:__isinstance({1, true})).to.be_false()
      end)
    end)

    describe('construction-time validation', function()
      it('should reject a non-final VARARG', function()
        expect(function() Tuple{VARARG, Integer} end).to.throw()
        expect(function() Tuple{Integer, VARARG, String} end)
          .to.throw()
      end)

      it('should reject a non-final Rest', function()
        expect(function() Tuple{Rest(Integer), String} end).to.throw()
        expect(function() Tuple{Integer, Rest(String), VARARG} end)
          .to.throw()
      end)

      it('should reject Rest without an element type', function()
        expect(function() Rest(nil) end)
          .to.throw('Rest: expected an element type')
        expect(function() Rest(false) end)
          .to.throw('Rest: expected an element type')
      end)
    end)

    describe('introspection', function()
      it('should expose the derived shape of a fixed tuple', function()
        local T = Tuple{Integer, String}
        expect(T.fixed_count).to.be_equal_to(2)
        expect(T.variadic).to.be_false()
        expect(T.rest_type).to.be_nil()
      end)

      it('should expose the derived shape of an unchecked '
        .. 'tail', function()
        local T = Tuple{Integer, String, VARARG}
        expect(T.fixed_count).to.be_equal_to(2)
        expect(T.variadic).to.be_true()
        expect(T.rest_type).to.be_nil()
      end)

      it('should expose the derived shape of a typed tail', function()
        local T = Tuple{Integer, Rest(Number)}
        expect(T.fixed_count).to.be_equal_to(1)
        expect(T.variadic).to.be_true()
        expect(T.rest_type).to.be_equal_to(Number)
      end)

      it('should expose element_type on the Rest marker', function()
        expect(Rest(Number).element_type).to.be_equal_to(Number)
        expect(tostring(Rest(Number))).to.be_equal_to('...Number')
      end)
    end)

    describe('llx.Tuple values', function()
      it('should accept Tuple values with variadic tails', function()
        local T = Tuple{Integer, VARARG}
        expect(T:__isinstance(TupleValue{1, 'x', true})).to.be_true()
        local Ints = Tuple{Rest(Integer)}
        expect(Ints:__isinstance(TupleValue{1, 2, 3})).to.be_true()
        expect(Ints:__isinstance(TupleValue{1, 'x'})).to.be_false()
      end)
    end)

    describe('composition', function()
      it('should compose inside Union', function()
        local U = Union{String, Tuple{Rest(Integer)}}
        expect(isinstance('hello', U)).to.be_true()
        expect(isinstance({1, 2, 3}, U)).to.be_true()
        expect(isinstance({1, 'two'}, U)).to.be_false()
      end)

      it('should compose inside Dict', function()
        local D = Dict(String, Tuple{Number, Rest(Number)})
        expect(isinstance({polyline = {0, 1, 2}}, D)).to.be_true()
        expect(isinstance({polyline = {}}, D)).to.be_false()
        expect(isinstance({polyline = {0, 'x'}}, D)).to.be_false()
      end)
    end)

    describe('standalone Rest markers', function()
      it('should not act as a matcher outside Tuple', function()
        -- Rest carries no __isinstance, so isinstance rejects it as
        -- a non-matcher (loudly, like every other non-matcher type
        -- argument) rather than silently returning false.
        local ok, err = pcall(isinstance, 1, Rest(Integer))
        expect(ok).to.be_false()
        expect(err.what:find(
            'expected a type matcher or class with __isinstance',
            1, true)).to_not.be_nil()
      end)

      it('should be recognized by the is_rest predicate', function()
        expect(matchers.is_rest(Rest(Integer))).to.be_true()
        expect(matchers.is_rest(Rest(Union{Integer, String})))
          .to.be_true()
      end)

      it('should not report non-Rest values as Rest', function()
        expect(matchers.is_rest(Integer)).to.be_false()
        expect(matchers.is_rest(VARARG)).to.be_false()
        expect(matchers.is_rest(nil)).to.be_false()
        expect(matchers.is_rest({element_type = Integer}))
          .to.be_false()
      end)
    end)
  end)

  describe('top-level llx namespace', function()
    it('should leave llx.Tuple as the value class', function()
      expect(llx.Tuple).to.be_equal_to(TupleValue)
      expect(tostring(llx.Tuple{1, 2})).to.be_equal_to('Tuple{1,2}')
    end)

    it('should export Rest at the top level', function()
      expect(llx.Rest).to.be_equal_to(Rest)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Protocol
-- ---------------------------------------------------------------------------

describe('Protocol', function()
  describe('__isinstance', function()
    it('should accept a table with all required fields', function()
      local UserShape = Protocol{name = String, age = Integer}
      expect(UserShape:__isinstance({name = 'Alice', age = 30}))
        .to.be_true()
    end)

    it('should reject a table missing a required field', function()
      local UserShape = Protocol{name = String, age = Integer}
      expect(UserShape:__isinstance({name = 'Bob'})).to.be_false()
    end)

    it('should reject a table with a wrong-typed field', function()
      local UserShape = Protocol{name = String, age = Integer}
      expect(UserShape:__isinstance({name = 42, age = 30}))
        .to.be_false()
    end)

    it('should accept extra fields (structural typing)', function()
      local UserShape = Protocol{name = String}
      expect(UserShape:__isinstance({name = 'X', extra = 'fine'}))
        .to.be_true()
    end)

    it('should reject non-table values', function()
      local Shape = Protocol{x = Integer}
      expect(Shape:__isinstance(42)).to.be_false()
      expect(Shape:__isinstance('x')).to.be_false()
      expect(Shape:__isinstance(nil)).to.be_false()
    end)

    it('should accept an empty protocol against any table', function()
      local Empty = Protocol{}
      expect(Empty:__isinstance({})).to.be_true()
      expect(Empty:__isinstance({a = 1})).to.be_true()
    end)
  end)

  describe('nested protocols', function()
    it('should compose with another Protocol as a field type', function()
      local Inner = Protocol{value = Integer}
      local Outer = Protocol{label = String, inner = Inner}
      expect(Outer:__isinstance({
        label = 'x',
        inner = {value = 1},
      })).to.be_true()
      expect(Outer:__isinstance({
        label = 'x',
        inner = {value = 'wrong'},
      })).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local Shape = Protocol{x = Integer, y = Integer}
      expect(isinstance({x = 1, y = 2}, Shape)).to.be_true()
      expect(isinstance({x = 1, y = 'two'}, Shape)).to.be_false()
    end)
  end)

  describe('__name', function()
    it('should expose a Protocol{...} name listing fields', function()
      local Shape = Protocol{a = Integer, b = String}
      expect(Shape.__name:find('Protocol')).to_not.be_nil()
      expect(Shape.__name:find('a')).to_not.be_nil()
      expect(Shape.__name:find('b')).to_not.be_nil()
    end)
  end)

  describe('fields field', function()
    it('should expose the underlying shape table', function()
      local Shape = Protocol{a = Integer}
      expect(Shape.fields.a).to.be_equal_to(Integer)
    end)
  end)

  describe('optional fields via Optional', function()
    local Contact = Protocol{
      name = String,
      email = Optional(String),
    }

    it('should accept a value with the optional field absent', function()
      expect(Contact:__isinstance({name = 'Alice'})).to.be_true()
    end)

    it('should accept a value with the optional field present '
      .. 'and well-typed', function()
      expect(Contact:__isinstance({
        name = 'Alice',
        email = 'alice@example.com',
      })).to.be_true()
    end)

    it('should reject a value whose optional field has the '
      .. 'wrong type', function()
      expect(Contact:__isinstance({name = 'Alice', email = 42}))
        .to.be_false()
    end)

    it('should still require the non-optional fields', function()
      expect(Contact:__isinstance({email = 'alice@example.com'}))
        .to.be_false()
    end)
  end)

  describe('closed shapes via __exact', function()
    local Point = Protocol{
      x = Integer,
      y = Integer,
      __exact = true,
    }

    it('should accept a value with exactly the declared fields', function()
      expect(Point:__isinstance({x = 1, y = 2})).to.be_true()
    end)

    it('should reject a value with an extra key', function()
      expect(Point:__isinstance({x = 1, y = 2, z = 3})).to.be_false()
    end)

    it('should reject a value with a typo\'d key', function()
      -- The declared fields still pass (x present, y missing would
      -- fail), so use a shape with an optional field to isolate the
      -- typo detection.
      local Named = Protocol{
        name = String,
        nickname = Optional(String),
        __exact = true,
      }
      expect(Named:__isinstance({name = 'A', nickame = 'B'}))
        .to.be_false()
    end)

    it('should accept a missing Optional field in exact mode', function()
      local Named = Protocol{
        name = String,
        nickname = Optional(String),
        __exact = true,
      }
      expect(Named:__isinstance({name = 'A'})).to.be_true()
      expect(Named:__isinstance({name = 'A', nickname = 'B'}))
        .to.be_true()
    end)

    it('should accept only the empty table for an empty exact '
      .. 'shape', function()
      local Empty = Protocol{__exact = true}
      expect(Empty:__isinstance({})).to.be_true()
      expect(Empty:__isinstance({a = 1})).to.be_false()
    end)

    it('should ignore metatable-provided fields (raw keys '
      .. 'only)', function()
      local value = setmetatable({x = 1, y = 2}, {
        __index = {z = 3},
        __pairs = function(t)
          return function() error('__pairs must not be called') end, t
        end,
      })
      expect(Point:__isinstance(value)).to.be_true()
    end)

    it('should reject non-table values', function()
      expect(Point:__isinstance(42)).to.be_false()
      expect(Point:__isinstance(nil)).to.be_false()
    end)

    it('should work as an isinstance target', function()
      expect(isinstance({x = 1, y = 2}, Point)).to.be_true()
      expect(isinstance({x = 1, y = 2, z = 3}, Point)).to.be_false()
    end)

    it('should expose exact and keep __exact out of fields', function()
      expect(Point.exact).to.be_true()
      expect(Point.fields.__exact).to.be_nil()
      expect(Point.fields.x).to.be_equal_to(Integer)
    end)

    it('should default to open shapes with exact = false', function()
      local Open = Protocol{x = Integer}
      expect(Open.exact).to.be_false()
      expect(Open:__isinstance({x = 1, extra = 'fine'})).to.be_true()
    end)

    it('should reject a non-boolean __exact value', function()
      expect(function() Protocol{x = Integer, __exact = 1} end)
        .to.throw('Protocol: __exact must be a boolean')
      expect(function() Protocol{x = Integer, __exact = 'yes'} end)
        .to.throw()
    end)

    it('should treat __exact = false as an open shape', function()
      local Open = Protocol{x = Integer, __exact = false}
      expect(Open.exact).to.be_false()
      expect(Open:__isinstance({x = 1, extra = 'fine'})).to.be_true()
      expect(Open.__name).to.be_equal_to('Protocol{x}')
    end)

    it('should encode exactness in the name', function()
      expect(Point.__name).to.be_equal_to('Protocol{x, y} exact')
      expect(tostring(Point)).to.be_equal_to('Protocol{x, y} exact')
      local Open = Protocol{x = Integer}
      expect(Open.__name).to.be_equal_to('Protocol{x}')
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Callable
-- ---------------------------------------------------------------------------

describe('Callable', function()
  describe('__name', function()
    it('should expose a Callable<(params) -> (returns)> name', function()
      local C = Callable({Integer}, {String})
      expect(C.__name).to.be_equal_to('Callable<(Integer) -> (String)>')
    end)

    it('should handle empty parameter and return lists', function()
      local C = Callable({}, {})
      expect(C.__name).to.be_equal_to('Callable<() -> ()>')
    end)

    it('should default omitted lists to empty', function()
      local C = Callable()
      expect(C.__name).to.be_equal_to('Callable<() -> ()>')
    end)

    it('should encode strictness in the name', function()
      local C = Callable({Integer}, {String}, {strict = true})
      expect(C.__name)
        .to.be_equal_to('Callable<(Integer) -> (String)> strict')
    end)
  end)

  describe('exposed fields', function()
    it('should expose params and returns for introspection', function()
      local params = {Integer, String}
      local returns = {Number}
      local C = Callable(params, returns)
      expect(C.params).to.be_equal_to(params)
      expect(C.returns).to.be_equal_to(returns)
    end)

    it('should expose strict, defaulting to false', function()
      expect(Callable({}, {}).strict).to.be_false()
      expect(Callable({}, {}, {strict = true}).strict).to.be_true()
    end)
  end)

  describe('raw functions (lenient by default)', function()
    it('should accept a function with matching arity', function()
      local C = Callable({Integer, Integer}, {Integer})
      expect(C:__isinstance(function(a, b) return a + b end)).to.be_true()
    end)

    it('should accept a function declaring fewer parameters', function()
      local C = Callable({Integer, Integer}, {Integer})
      expect(C:__isinstance(function(a) return a end)).to.be_true()
    end)

    it('should reject a function declaring more parameters', function()
      local C = Callable({Integer}, {Integer})
      expect(C:__isinstance(function(a, b, c) return a end)).to.be_false()
    end)

    it('should accept a vararg function for any parameter list', function()
      local C = Callable({Integer, String, Number}, {String})
      expect(C:__isinstance(function(...) return ... end)).to.be_true()
    end)

    it('should accept any function for a variadic parameter '
      .. 'list', function()
      -- A trailing VARARG allows arbitrary extra arguments, so the
      -- upper bound on the declared arity disappears: a function
      -- declaring more parameters than the fixed prefix legitimately
      -- consumes values from the variadic tail.
      local C = Callable({Integer, VARARG}, {Integer})
      expect(C:__isinstance(function(a) return a end)).to.be_true()
      expect(C:__isinstance(function(a, b, c) return a end)).to.be_true()
      expect(C:__isinstance(function(...) return ... end)).to.be_true()
      expect(C:__isinstance(function() return 0 end)).to.be_true()
    end)
  end)

  describe('raw functions (strict)', function()
    it('should accept only an exact arity match', function()
      local C = Callable({Integer, Integer}, {Integer}, {strict = true})
      expect(C:__isinstance(function(a, b) return a + b end)).to.be_true()
      expect(C:__isinstance(function(a) return a end)).to.be_false()
      expect(C:__isinstance(function(a, b, c) return a end)).to.be_false()
    end)

    it('should reject a vararg function', function()
      local C = Callable({Integer}, {Integer}, {strict = true})
      expect(C:__isinstance(function(...) return ... end)).to.be_false()
    end)

    it('should require an exactly matching variadic shape for a '
      .. 'variadic parameter list', function()
      -- Strict pins the declared shape: the function must itself be
      -- vararg and declare exactly the fixed prefix's parameters.
      local C = Callable({String, VARARG}, {}, {strict = true})
      expect(C:__isinstance(function(fmt, ...) return fmt, ... end))
        .to.be_true()
      expect(C:__isinstance(function(fmt) return fmt end)).to.be_false()
      expect(C:__isinstance(function(fmt, a, ...) return a end))
        .to.be_false()
      expect(C:__isinstance(function(...) return ... end)).to.be_false()
    end)

    it('should accept a C function only against a bare variadic '
      .. 'parameter list', function()
      -- debug.getinfo reports every C function as vararg with
      -- nparams == 0, exactly the declared shape of Callable({'...'}).
      local Bare = Callable({VARARG}, {}, {strict = true})
      local Prefixed = Callable({String, VARARG}, {}, {strict = true})
      expect(Bare:__isinstance(print)).to.be_true()
      expect(Prefixed:__isinstance(print)).to.be_false()
    end)
  end)

  describe('VARARG placement', function()
    it('should reject a non-trailing VARARG at construction', function()
      expect(function() Callable({VARARG, Integer}, {}) end).to.throw()
      expect(function() Callable({}, {VARARG, Integer}) end).to.throw()
    end)

    it('should accept a trailing VARARG in params and returns',
        function()
      expect(function()
        Callable({Integer, VARARG}, {Integer, VARARG})
      end).to_not.throw()
    end)
  end)

  describe('Rest placement', function()
    local ValueException =
        require 'llx.exceptions' . ValueException

    local function expect_rest_rejection(build)
      local ok, err = pcall(build)
      expect(ok).to.be_false()
      expect(isinstance(err, ValueException)).to.be_true()
      expect(err.what:find('Rest(T) is only valid inside Tuple',
                           1, true)).to_not.be_nil()
    end

    it('should reject Rest(T) in the parameter list', function()
      expect_rest_rejection(function()
        return Callable({Rest(Integer)}, {})
      end)
      expect_rest_rejection(function()
        return Callable({Integer, Rest(String)}, {})
      end)
    end)

    it('should reject Rest(T) in the return list', function()
      expect_rest_rejection(function()
        return Callable({}, {Rest(Integer)})
      end)
      expect_rest_rejection(function()
        return Callable({String, Rest(Integer)}, {Integer})
      end)
    end)
  end)

  describe('Signature-wrapped functions', function()
    local function make_wrapped(params, returns)
      return signature.Function{
        params = params,
        returns = returns,
        func = function(...) return ... end,
      }
    end

    it('should accept a wrapper with a matching signature', function()
      local wrapped = make_wrapped({Integer}, {String})
      local C = Callable({Integer}, {String})
      expect(C:__isinstance(wrapped)).to.be_true()
    end)

    it('should reject a wrapper with mismatched parameters', function()
      local wrapped = make_wrapped({String}, {String})
      local C = Callable({Integer}, {String})
      expect(C:__isinstance(wrapped)).to.be_false()
    end)

    it('should reject a wrapper with mismatched returns', function()
      local wrapped = make_wrapped({Integer}, {Integer})
      local C = Callable({Integer}, {String})
      expect(C:__isinstance(wrapped)).to.be_false()
    end)

    it('should reject a wrapper with a different parameter count', function()
      local wrapped = make_wrapped({Integer, Integer}, {String})
      local C = Callable({Integer}, {String})
      expect(C:__isinstance(wrapped)).to.be_false()
    end)

    it('should compare structurally equal matchers by name', function()
      local wrapped = make_wrapped({Dict(String, Integer)}, {String})
      local C = Callable({Dict(String, Integer)}, {String})
      expect(C:__isinstance(wrapped)).to.be_true()
    end)

    it('should match string type names against matcher names', function()
      -- Signature declarations may name a type by string, e.g.
      -- Signature{params={'MyClass', Integer}, ...}.
      local wrapped = make_wrapped({'Integer'}, {'String'})
      local C = Callable({Integer}, {String})
      expect(C:__isinstance(wrapped)).to.be_true()
    end)

    it('should not match distinct anonymous classes by name', function()
      local A = llx.class {}
      local B = llx.class {}
      local wrapped = make_wrapped({A}, {})
      expect(Callable({A}, {}):__isinstance(wrapped)).to.be_true()
      expect(Callable({B}, {}):__isinstance(wrapped)).to.be_false()
    end)

    it('should distinguish strict and lenient Callable '
      .. 'parameters by name', function()
      local Lenient = Callable({Integer}, {Integer})
      local Strict = Callable({Integer}, {Integer}, {strict = true})
      local wrapped = make_wrapped({Lenient}, {})
      expect(Callable({Lenient}, {}):__isinstance(wrapped)).to.be_true()
      expect(Callable({Strict}, {}):__isinstance(wrapped)).to.be_false()
    end)

    it('should accept a variadic wrapper where its checked prefix '
      .. 'is covered', function()
      local wrapped = make_wrapped({Integer, VARARG}, {})
      expect(Callable({Integer, String}, {}):__isinstance(wrapped))
        .to.be_true()
      expect(Callable({Integer, VARARG}, {}):__isinstance(wrapped))
        .to.be_true()
      expect(Callable({String}, {}):__isinstance(wrapped))
        .to.be_false()
    end)

    it('should reject a fixed wrapper against a variadic '
      .. 'Callable', function()
      local wrapped = make_wrapped({Integer}, {})
      expect(Callable({Integer, VARARG}, {}):__isinstance(wrapped))
        .to.be_false()
    end)

    it('should reject a wrapper declaring variadic returns against '
      .. 'fixed returns', function()
      local wrapped = make_wrapped({}, {Integer, VARARG})
      expect(Callable({}, {Integer}):__isinstance(wrapped))
        .to.be_false()
      expect(Callable({}, {Integer, VARARG}):__isinstance(wrapped))
        .to.be_true()
    end)
  end)

  describe('callable tables', function()
    it('should accept a table with a __call metamethod', function()
      local C = Callable({Integer}, {Integer})
      local callable_table = setmetatable({}, {
        __call = function(self, x) return x end,
      })
      expect(C:__isinstance(callable_table)).to.be_true()
    end)

    it('should reject a plain table', function()
      local C = Callable({Integer}, {Integer})
      expect(C:__isinstance({})).to.be_false()
    end)

    it('should reject non-callable values', function()
      local C = Callable({Integer}, {Integer})
      expect(C:__isinstance(42)).to.be_false()
      expect(C:__isinstance('hello')).to.be_false()
      expect(C:__isinstance(nil)).to.be_false()
      expect(C:__isinstance(true)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local C = Callable({Integer}, {Integer})
      expect(isinstance(function(x) return x end, C)).to.be_true()
      expect(isinstance(42, C)).to.be_false()
    end)
  end)

  describe('composition', function()
    it('should compose inside Union', function()
      local C = Callable({Integer}, {Integer})
      local U = Union{String, C}
      expect(isinstance('hello', U)).to.be_true()
      expect(isinstance(function(x) return x end, U)).to.be_true()
      expect(isinstance(42, U)).to.be_false()
    end)

    it('should compose inside Protocol', function()
      local Comparator = Protocol{
        name = String,
        compare = Callable({Any, Any}, {Integer}),
      }
      expect(isinstance({
        name = 'by_value',
        compare = function(a, b) return 0 end,
      }, Comparator)).to.be_true()
      expect(isinstance({
        name = 'broken',
        compare = 'not a function',
      }, Comparator)).to.be_false()
    end)

    it('should compose inside Dict', function()
      local Handlers = Dict(String, Callable({Any}, {}))
      expect(isinstance({
        on_open = function(event) end,
        on_close = function(event) end,
      }, Handlers)).to.be_true()
      expect(isinstance({on_open = 'nope'}, Handlers)).to.be_false()
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Literal
-- ---------------------------------------------------------------------------

describe('Literal', function()
  describe('__name', function()
    it('should expose a Literal{...} name listing the values', function()
      local L = Literal{'active', 'pending', 'closed'}
      expect(L.__name)
        .to.be_equal_to("Literal{'active', 'pending', 'closed'}")
    end)

    it('should render number and boolean values unquoted', function()
      local L = Literal{1, 2.5, true}
      expect(L.__name).to.be_equal_to('Literal{1, 2.5, true}')
    end)

    it('should be used as the tostring form', function()
      local L = Literal{'a'}
      expect(tostring(L)).to.be_equal_to("Literal{'a'}")
    end)
  end)

  describe('values field', function()
    it('should expose the allowed values', function()
      local values = {'active', 'pending'}
      local L = Literal(values)
      expect(L.values).to.be_equal_to(values)
    end)
  end)

  describe('construction-time validation', function()
    it('should reject table values', function()
      expect(function() Literal{{}} end)
        .to.throw('Literal: values must be strings, numbers, or '
          .. 'booleans; got table')
    end)

    it('should reject a table value mixed with valid values', function()
      expect(function() Literal{'ok', {}} end).to.throw()
    end)

    it('should reject function values', function()
      expect(function() Literal{function() end} end).to.throw()
    end)

    it('should reject an empty value list', function()
      expect(function() Literal{} end)
        .to.throw('Literal: expected at least one value')
    end)

    it('should reject a non-table argument', function()
      expect(function() Literal('active') end)
        .to.throw('Literal: expected a list of allowed values')
    end)
  end)

  describe('__isinstance on strings', function()
    it('should accept each allowed string', function()
      local Status = Literal{'active', 'pending', 'closed'}
      expect(Status:__isinstance('active')).to.be_true()
      expect(Status:__isinstance('pending')).to.be_true()
      expect(Status:__isinstance('closed')).to.be_true()
    end)

    it('should reject a string not in the allowed set', function()
      local Status = Literal{'active', 'pending'}
      expect(Status:__isinstance('archived')).to.be_false()
    end)

    it('should reject non-string values', function()
      local Status = Literal{'active'}
      expect(Status:__isinstance(42)).to.be_false()
      expect(Status:__isinstance(true)).to.be_false()
      expect(Status:__isinstance(nil)).to.be_false()
      expect(Status:__isinstance({})).to.be_false()
    end)
  end)

  describe('__isinstance on numbers', function()
    it('should accept each allowed number', function()
      local Level = Literal{1, 2, 3}
      expect(Level:__isinstance(1)).to.be_true()
      expect(Level:__isinstance(3)).to.be_true()
    end)

    it('should reject a number not in the allowed set', function()
      local Level = Literal{1, 2, 3}
      expect(Level:__isinstance(4)).to.be_false()
      expect(Level:__isinstance(1.5)).to.be_false()
    end)

    it('should reject the string form of an allowed number', function()
      local Level = Literal{1}
      expect(Level:__isinstance('1')).to.be_false()
    end)
  end)

  describe('__isinstance on booleans', function()
    it('should accept an allowed boolean', function()
      local OnlyTrue = Literal{true}
      expect(OnlyTrue:__isinstance(true)).to.be_true()
    end)

    it('should reject the other boolean', function()
      local OnlyTrue = Literal{true}
      expect(OnlyTrue:__isinstance(false)).to.be_false()
    end)

    it('should reject nil for Literal{false}', function()
      local OnlyFalse = Literal{false}
      expect(OnlyFalse:__isinstance(false)).to.be_true()
      expect(OnlyFalse:__isinstance(nil)).to.be_false()
    end)
  end)

  describe('mixed value types', function()
    it('should accept values of any allowed scalar type', function()
      local Mixed = Literal{'auto', 0, false}
      expect(Mixed:__isinstance('auto')).to.be_true()
      expect(Mixed:__isinstance(0)).to.be_true()
      expect(Mixed:__isinstance(false)).to.be_true()
      expect(Mixed:__isinstance('manual')).to.be_false()
      expect(Mixed:__isinstance(1)).to.be_false()
      expect(Mixed:__isinstance(true)).to.be_false()
    end)
  end)

  describe('isinstance integration', function()
    it('should work as an isinstance target', function()
      local Status = Literal{'active', 'pending'}
      expect(isinstance('active', Status)).to.be_true()
      expect(isinstance('archived', Status)).to.be_false()
    end)
  end)

  describe('composition', function()
    it('should compose inside Union', function()
      local U = Union{Literal{'a'}, Literal{'b'}, Nil}
      expect(isinstance('a', U)).to.be_true()
      expect(isinstance('b', U)).to.be_true()
      expect(isinstance(nil, U)).to.be_true()
      expect(isinstance('c', U)).to.be_false()
    end)

    it('should compose inside Protocol as a tag field', function()
      local Shape = Protocol{
        kind = Literal{'circle', 'square'},
        size = Number,
      }
      expect(isinstance({kind = 'circle', size = 1.0}, Shape))
        .to.be_true()
      expect(isinstance({kind = 'square', size = 2.0}, Shape))
        .to.be_true()
      expect(isinstance({kind = 'triangle', size = 3.0}, Shape))
        .to.be_false()
    end)

    it('should compose inside Dict', function()
      local D = Dict(String, Literal{'on', 'off'})
      expect(isinstance({a = 'on', b = 'off'}, D)).to.be_true()
      expect(isinstance({a = 'maybe'}, D)).to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.Literal', function()
      expect(llx.Literal).to.be_equal_to(Literal)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- NewType
-- ---------------------------------------------------------------------------

describe('NewType', function()
  local NewType = matchers.NewType

  describe('matcher identity', function()
    it('should carry the given name', function()
      local UserId = NewType('UserId', Integer)
      expect(UserId.__name).to.be_equal_to('UserId')
      expect(tostring(UserId)).to.be_equal_to('UserId')
    end)

    it('should expose the base type', function()
      local UserId = NewType('UserId', Integer)
      expect(UserId.base_type).to.be_equal_to(Integer)
    end)

    it('should reject a non-string name', function()
      expect(function() NewType(42, Integer) end).to.throw()
    end)

    it('should reject a base without __isinstance', function()
      expect(function() NewType('X', 5) end).to.throw()
      expect(function() NewType('X', {}) end).to.throw()
    end)
  end)

  describe('constructor', function()
    it('should brand a value of the base type', function()
      local UserId = NewType('UserId', Integer)
      local id = UserId(42)
      expect(isinstance(id, UserId)).to.be_true()
    end)

    it('should reject a value of the wrong base type', function()
      local UserId = NewType('UserId', Integer)
      expect(function() UserId('42') end).to.throw()
      expect(function() UserId(1.5) end).to.throw()
    end)

    it('should describe a rejected class instance by its class',
        function()
      -- The rejection message uses the shared class-aware describe
      -- helper, so a class instance reads as "an instance of Animal"
      -- rather than a bare "table" (issue #67).
      local Animal = llx.class 'Animal' {}
      local UserId = NewType('UserId', Integer)
      expect(function() UserId(Animal()) end).to.throw(
          'UserId: expected Integer, got an instance of Animal')
    end)

    it('should reject nil', function()
      local UserId = NewType('UserId', Integer)
      expect(function() UserId(nil) end).to.throw()
    end)

    it('should return an already-branded value unchanged', function()
      local UserId = NewType('UserId', Integer)
      local id = UserId(42)
      expect(rawequal(UserId(id), id)).to.be_true()
    end)
  end)

  describe('isinstance', function()
    it('should not match the raw base value', function()
      local UserId = NewType('UserId', Integer)
      expect(isinstance(42, UserId)).to.be_false()
    end)

    it('should not match a sibling brand', function()
      local UserId = NewType('UserId', Integer)
      local OrderId = NewType('OrderId', Integer)
      expect(isinstance(UserId(42), OrderId)).to.be_false()
      expect(isinstance(OrderId(42), UserId)).to.be_false()
    end)

    it('should not match arbitrary tables', function()
      local UserId = NewType('UserId', Integer)
      expect(isinstance({}, UserId)).to.be_false()
      expect(isinstance(setmetatable({}, {}), UserId)).to.be_false()
    end)

    it('should match Any', function()
      local UserId = NewType('UserId', Integer)
      expect(isinstance(UserId(42), Any)).to.be_true()
    end)
  end)

  describe('unwrapping', function()
    it('should unwrap explicitly via get', function()
      local UserId = NewType('UserId', Integer)
      expect(UserId(42):get()).to.be_equal_to(42)
    end)
  end)

  describe('operator forwarding', function()
    it('should forward arithmetic to the underlying value', function()
      local UserId = NewType('UserId', Integer)
      expect(UserId(40) + 2).to.be_equal_to(42)
      expect(UserId(44) - UserId(2)).to.be_equal_to(42)
      expect(UserId(21) * 2).to.be_equal_to(42)
      expect(UserId(85) // 2).to.be_equal_to(42)
      expect(UserId(85) % 43).to.be_equal_to(42)
      expect(-UserId(42)).to.be_equal_to(-42)
    end)

    it('should forward comparisons', function()
      local UserId = NewType('UserId', Integer)
      expect(UserId(1) < UserId(2)).to.be_true()
      expect(UserId(2) < UserId(1)).to.be_false()
      expect(UserId(1) <= UserId(1)).to.be_true()
      expect(UserId(1) < 2).to.be_true()
    end)

    it('should compare equal on the underlying value', function()
      local UserId = NewType('UserId', Integer)
      local OrderId = NewType('OrderId', Integer)
      expect(UserId(1) == UserId(1)).to.be_true()
      expect(UserId(1) == UserId(2)).to.be_false()
      -- Equality is erased across brands, matching Python's
      -- runtime-erased NewType.
      expect(UserId(1) == OrderId(1)).to.be_true()
    end)

    it('should forward concat, len, and tostring for string '
        .. 'bases', function()
      local Name = NewType('Name', String)
      expect(Name('ab') .. '!').to.be_equal_to('ab!')
      expect('<' .. Name('ab')).to.be_equal_to('<ab')
      expect(#Name('abc')).to.be_equal_to(3)
      expect(tostring(Name('ab'))).to.be_equal_to('ab')
    end)

    it('should forward calls for function bases', function()
      local Handler = NewType('Handler', llx.Function)
      local double = Handler(function(x) return x * 2 end)
      expect(double(21)).to.be_equal_to(42)
    end)

    it('should hash equal payloads equally', function()
      local UserId = NewType('UserId', Integer)
      local OrderId = NewType('OrderId', Integer)
      local hash = llx.hash.hash
      expect(hash(UserId(42))).to.be_equal_to(hash(OrderId(42)))
      expect(hash(UserId(1)) == hash(UserId(2))).to.be_false()
    end)
  end)

  describe('table bases', function()
    it('should forward field reads', function()
      local Point = NewType('Point', llx.Table)
      local p = Point({x = 1, y = 2})
      expect(p.x).to.be_equal_to(1)
      expect(p.y).to.be_equal_to(2)
    end)

    it('should be read-only through the wrapper', function()
      local Point = NewType('Point', llx.Table)
      local p = Point({x = 1})
      expect(function() p.x = 5 end).to.throw()
    end)

    it('should allow mutation through get', function()
      local Point = NewType('Point', llx.Table)
      local p = Point({x = 1})
      p:get().x = 5
      expect(p.x).to.be_equal_to(5)
    end)

    it('should not compare equal to its unbranded payload', function()
      -- Keeps == consistent with __hash: llx.hash mixes the outer
      -- type name into a table's hash, so a wrapper and its raw
      -- payload can never hash equally and must not compare equal.
      local Point = NewType('Point', llx.Table)
      local payload = {x = 1}
      local p = Point(payload)
      expect(p == payload).to.be_false()
      expect(payload == p).to.be_false()
      expect(p == Point(payload)).to.be_true()
    end)
  end)

  describe('nested brands', function()
    it('should brand over another NewType', function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      local admin = AdminId(UserId(7))
      expect(isinstance(admin, AdminId)).to.be_true()
      expect(isinstance(admin, UserId)).to.be_true()
    end)

    it('should reject an unbranded value for a nested brand',
        function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      expect(function() AdminId(7) end).to.throw()
    end)

    it('should not match the outer brand from the inner', function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      expect(isinstance(UserId(7), AdminId)).to.be_false()
    end)

    it('should unwrap one brand level via get', function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      local admin = AdminId(UserId(7))
      expect(isinstance(admin:get(), UserId)).to.be_true()
      expect(admin:get():get()).to.be_equal_to(7)
    end)

    it('should forward operators through the whole chain', function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      local admin = AdminId(UserId(7))
      expect(admin + 1).to.be_equal_to(8)
      expect(admin == UserId(7)).to.be_true()
    end)
  end)

  describe('composition', function()
    it('should compose inside Union', function()
      local UserId = NewType('UserId', Integer)
      local OrderId = NewType('OrderId', Integer)
      local AnyId = Union{UserId, OrderId}
      expect(isinstance(UserId(1), AnyId)).to.be_true()
      expect(isinstance(OrderId(1), AnyId)).to.be_true()
      expect(isinstance(1, AnyId)).to.be_false()
    end)

    it('should compose inside Optional', function()
      local UserId = NewType('UserId', Integer)
      local MaybeId = Optional(UserId)
      expect(isinstance(nil, MaybeId)).to.be_true()
      expect(isinstance(UserId(1), MaybeId)).to.be_true()
      expect(isinstance(1, MaybeId)).to.be_false()
    end)

    it('should compose inside Protocol', function()
      local UserId = NewType('UserId', Integer)
      local User = Protocol{
        id = UserId,
        name = String,
      }
      expect(isinstance({id = UserId(1), name = 'ada'}, User))
        .to.be_true()
      expect(isinstance({id = 1, name = 'ada'}, User))
        .to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.NewType', function()
      expect(llx.NewType).to.be_equal_to(NewType)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- ClassOf
-- ---------------------------------------------------------------------------

describe('ClassOf', function()
  local class = llx.class
  local Animal = class 'Animal' {}
  local Dog = class 'Dog' : extends(Animal) {}
  local Puppy = class 'Puppy' : extends(Dog) {}
  local Rock = class 'Rock' {}

  describe('__name', function()
    it('should have __name ClassOf<Animal>', function()
      expect(ClassOf(Animal).__name).to.be_equal_to('ClassOf<Animal>')
    end)

    it('should have __name ClassOf for the bare form', function()
      expect(ClassOf().__name).to.be_equal_to('ClassOf')
    end)
  end)

  describe('__tostring', function()
    it('should stringify with the base class name', function()
      expect(tostring(ClassOf(Animal)))
        .to.be_equal_to('ClassOf<Animal>')
    end)

    it('should stringify the bare form as ClassOf', function()
      expect(tostring(ClassOf())).to.be_equal_to('ClassOf')
    end)
  end)

  describe('introspection', function()
    it('should expose the base class', function()
      expect(ClassOf(Animal).base_class).to.be_equal_to(Animal)
    end)

    it('should expose a nil base for the bare form', function()
      expect(ClassOf().base_class).to.be_equal_to(nil)
    end)
  end)

  describe('__isinstance', function()
    local OfAnimal = ClassOf(Animal)

    it('should match the base class itself', function()
      expect(isinstance(Animal, OfAnimal)).to.be_true()
    end)

    it('should match a direct subclass', function()
      expect(isinstance(Dog, OfAnimal)).to.be_true()
    end)

    it('should match a transitive subclass', function()
      expect(isinstance(Puppy, OfAnimal)).to.be_true()
    end)

    it('should reject an unrelated class', function()
      expect(isinstance(Rock, OfAnimal)).to.be_false()
    end)

    it('should reject a superclass of the base', function()
      expect(isinstance(Animal, ClassOf(Dog))).to.be_false()
    end)

    it('should reject an instance of the base class', function()
      expect(isinstance(Animal(), OfAnimal)).to.be_false()
    end)

    it('should reject an instance of a subclass', function()
      expect(isinstance(Puppy(), OfAnimal)).to.be_false()
    end)

    it('should reject non-tables', function()
      expect(isinstance(nil, OfAnimal)).to.be_false()
      expect(isinstance(42, OfAnimal)).to.be_false()
      expect(isinstance('Animal', OfAnimal)).to.be_false()
      expect(isinstance(true, OfAnimal)).to.be_false()
      expect(isinstance(function() end, OfAnimal)).to.be_false()
    end)

    it('should reject a plain table', function()
      expect(isinstance({}, OfAnimal)).to.be_false()
    end)

    it('should reject a table posing as its own metatable', function()
      -- Mimics the proxy's self-metatable shape without being a
      -- class: the __is_llx_class flag must also be present.
      local imposter = {}
      setmetatable(imposter, {__metatable = imposter})
      expect(isinstance(imposter, OfAnimal)).to.be_false()
      expect(isinstance(imposter, ClassOf())).to.be_false()
    end)

    it('should reject a type matcher', function()
      expect(isinstance(Integer, OfAnimal)).to.be_false()
    end)

    it('should support an anonymous base class', function()
      local Base = class {}
      local Derived = class 'Derived' : extends(Base) {}
      local OfBase = ClassOf(Base)
      expect(isinstance(Base, OfBase)).to.be_true()
      expect(isinstance(Derived, OfBase)).to.be_true()
      expect(isinstance(Rock, OfBase)).to.be_false()
    end)

    it('should walk multiple inheritance', function()
      local Robot = class 'Robot' {}
      local RoboDog = class 'RoboDog' : extends(Animal, Robot) {}
      expect(isinstance(RoboDog, ClassOf(Animal))).to.be_true()
      expect(isinstance(RoboDog, ClassOf(Robot))).to.be_true()
      expect(isinstance(RoboDog, ClassOf(Rock))).to.be_false()
    end)
  end)

  describe('bare ClassOf()', function()
    local AnyClass = ClassOf()

    it('should match any class', function()
      expect(isinstance(Animal, AnyClass)).to.be_true()
      expect(isinstance(Puppy, AnyClass)).to.be_true()
      expect(isinstance(Rock, AnyClass)).to.be_true()
    end)

    it('should match an anonymous class', function()
      local Anonymous = class {}
      expect(isinstance(Anonymous, AnyClass)).to.be_true()
    end)

    it('should reject instances and plain values', function()
      expect(isinstance(Animal(), AnyClass)).to.be_false()
      expect(isinstance({}, AnyClass)).to.be_false()
      expect(isinstance(42, AnyClass)).to.be_false()
      expect(isinstance(nil, AnyClass)).to.be_false()
    end)
  end)

  describe('argument validation', function()
    it('should raise on a string class name', function()
      expect(function() ClassOf('Animal') end)
        .to.throw('ClassOf: expected a class object (or no '
          .. "argument), got string 'Animal'")
    end)

    it('should raise on a type matcher base', function()
      expect(function() ClassOf(Integer) end).to.throw()
      expect(function() ClassOf(Union{Integer, String}) end)
        .to.throw()
    end)

    it('should raise on an instance base', function()
      expect(function() ClassOf(Animal()) end)
        .to.throw('ClassOf: expected a class object (or no '
          .. 'argument), got an instance of Animal '
          .. '(pass the class itself)')
    end)

    it('should raise on other non-class values', function()
      expect(function() ClassOf(42) end).to.throw()
      expect(function() ClassOf(true) end).to.throw()
      expect(function() ClassOf({}) end).to.throw()
    end)
  end)

  describe('composition', function()
    it('should compose inside Union', function()
      local ClassOrName = Union{ClassOf(Animal), String}
      expect(isinstance(Dog, ClassOrName)).to.be_true()
      expect(isinstance('Dog', ClassOrName)).to.be_true()
      expect(isinstance(Rock, ClassOrName)).to.be_false()
      expect(isinstance(Dog(), ClassOrName)).to.be_false()
    end)

    it('should compose inside Protocol', function()
      local Registration = Protocol{
        name = String,
        entity_class = ClassOf(Animal),
      }
      expect(isinstance(
        {name = 'dog', entity_class = Dog}, Registration))
        .to.be_true()
      expect(isinstance(
        {name = 'rock', entity_class = Rock}, Registration))
        .to.be_false()
      expect(isinstance(
        {name = 'dog', entity_class = Dog()}, Registration))
        .to.be_false()
    end)

    it('should compose inside Dict', function()
      local Registry = Dict(String, ClassOf(Animal))
      expect(isinstance({dog = Dog, puppy = Puppy}, Registry))
        .to.be_true()
      expect(isinstance({dog = Dog, rock = Rock}, Registry))
        .to.be_false()
      expect(isinstance({dog = Dog()}, Registry))
        .to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.ClassOf', function()
      expect(llx.ClassOf).to.be_equal_to(ClassOf)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Lazy
-- ---------------------------------------------------------------------------

describe('Lazy', function()
  describe('construction', function()
    it('should raise on a non-callable thunk', function()
      expect(function() Lazy(nil) end)
        .to.throw('Lazy: expected a callable thunk, got nil')
      expect(function() Lazy(42) end)
        .to.throw('Lazy: expected a callable thunk, got number')
      expect(function() Lazy('Integer') end)
        .to.throw('Lazy: expected a callable thunk, got string')
    end)

    it('should accept a callable table as the thunk', function()
      local thunk = setmetatable({}, {
        __call = function() return Integer end,
      })
      expect(isinstance(1, Lazy(thunk))).to.be_true()
    end)

    it('should not call the thunk at construction', function()
      local called = false
      Lazy(function() called = true; return Integer end)
      expect(called).to.be_false()
    end)
  end)

  describe('__name and tostring', function()
    it('should report a placeholder before resolution', function()
      local L = Lazy(function() return Integer end)
      expect(L.__name).to.start_with('Lazy<?#')
      expect(tostring(L)).to.be_equal_to(L.__name)
    end)

    it('should give each unresolved Lazy a distinct placeholder, so '
      .. 'containers embedding different unresolved references never '
      .. 'freeze the same name', function()
      local A = Lazy(function() return Integer end)
      local B = Lazy(function() return String end)
      expect(A.__name).to_not.be_equal_to(B.__name)
      expect(ListOf(A).__name).to_not.be_equal_to(ListOf(B).__name)
    end)

    it('should not force resolution when the name is read', function()
      local calls = 0
      local L = Lazy(function() calls = calls + 1; return Integer end)
      local _ = L.__name
      local _ = tostring(L)
      expect(calls).to.be_equal_to(0)
    end)

    it('should adopt the resolved name after resolution', function()
      local L = Lazy(function() return Integer end)
      isinstance(1, L)
      expect(L.__name).to.be_equal_to('Integer')
      expect(tostring(L)).to.be_equal_to('Integer')
    end)
  end)

  describe('__isinstance', function()
    it('should defer to the resolved matcher', function()
      local L = Lazy(function() return Integer end)
      expect(isinstance(1, L)).to.be_true()
      expect(isinstance(1.5, L)).to.be_false()
      expect(isinstance('one', L)).to.be_false()
    end)

    it('should support a forward reference to a matcher defined '
      .. 'later', function()
      local Element
      local Wrapper = Protocol{
        element = Lazy(function() return Element end),
      }
      Element = Union{Integer, String}
      expect(isinstance({element = 1}, Wrapper)).to.be_true()
      expect(isinstance({element = 'one'}, Wrapper)).to.be_true()
      expect(isinstance({element = true}, Wrapper)).to.be_false()
    end)

    it('should call the thunk once and cache the resolution',
        function()
      local calls = 0
      local L = Lazy(function() calls = calls + 1; return Integer end)
      expect(isinstance(1, L)).to.be_true()
      expect(isinstance(2, L)).to.be_true()
      expect(isinstance('x', L)).to.be_false()
      expect(calls).to.be_equal_to(1)
    end)

    it('should not cache a thunk error, so a later check retries',
        function()
      local attempts = 0
      local L = Lazy(function()
        attempts = attempts + 1
        if attempts == 1 then
          error('transient failure')
        end
        return Integer
      end)
      expect(function() isinstance(1, L) end).to.throw()
      expect(isinstance(1, L)).to.be_true()
      expect(attempts).to.be_equal_to(2)
    end)
  end)

  describe('resolution errors', function()
    it('should raise on a thunk returning nil (the undeclared-local '
      .. 'pitfall)', function()
      -- `local T = Union{..., Lazy(function() return T end)}` captures
      -- an outer (nil) T; the error message points at the fix.
      local L = Lazy(function() return nil end)
      expect(function() isinstance(1, L) end)
        .to.throw('Lazy: thunk returned nil; expected a type matcher '
          .. 'or class with __isinstance (declare the local before '
          .. "assigning it: 'local T' on its own line, then "
          .. "'T = ...')")
    end)

    it('should raise on a thunk returning a non-matcher', function()
      local L = Lazy(function() return 42 end)
      expect(function() isinstance(1, L) end)
        .to.throw('Lazy: thunk returned number 42; expected a type '
          .. 'matcher or class with __isinstance')
      local L2 = Lazy(function() return {} end)
      expect(function() isinstance(1, L2) end)
        .to.throw('Lazy: thunk returned table; expected a type '
          .. 'matcher or class with __isinstance')
    end)

    it('should raise on a direct self-resolution cycle', function()
      local L
      L = Lazy(function() return L end)
      expect(function() isinstance(1, L) end).to.throw()
    end)

    it('should raise on a cycle through a chain of Lazy matchers',
        function()
      local A, B
      A = Lazy(function() return B end)
      B = Lazy(function() return A end)
      expect(function() isinstance(1, A) end).to.throw()
      expect(function() isinstance(1, B) end).to.throw()
    end)
  end)

  describe('chains of Lazy', function()
    it('should flatten a Lazy resolving to another Lazy', function()
      local inner = Lazy(function() return Integer end)
      local outer = Lazy(function() return inner end)
      expect(isinstance(1, outer)).to.be_true()
      expect(isinstance('x', outer)).to.be_false()
      expect(outer.__name).to.be_equal_to('Integer')
    end)
  end)

  describe('resolve_lazy', function()
    it('should force a Lazy and return the resolved matcher',
        function()
      local L = Lazy(function() return Integer end)
      expect(resolve_lazy(L)).to.be_equal_to(Integer)
    end)

    it('should pass non-Lazy values through unchanged', function()
      expect(resolve_lazy(Integer)).to.be_equal_to(Integer)
      expect(resolve_lazy(nil)).to.be_equal_to(nil)
      expect(resolve_lazy('Integer')).to.be_equal_to('Integer')
    end)
  end)

  describe('recursive types', function()
    it('should express a recursive JSON document type', function()
      local Json
      Json = Union{String, Number, Boolean, Nil,
                   ListOf(Lazy(function() return Json end)),
                   Dict(String, Lazy(function() return Json end))}
      expect(isinstance('text', Json)).to.be_true()
      expect(isinstance(42, Json)).to.be_true()
      expect(isinstance(true, Json)).to.be_true()
      expect(isinstance(nil, Json)).to.be_true()
      expect(isinstance({1, 'two', {3, 4}}, Json)).to.be_true()
      expect(isinstance({
        name = 'llx',
        tags = {'lua', 'types'},
        meta = {stars = 42, active = true},
      }, Json)).to.be_true()
      expect(isinstance(print, Json)).to.be_false()
      expect(isinstance({1, print}, Json)).to.be_false()
      -- A hash-only table with invalid values is rejected: the Dict
      -- branch rejects the bad value, and ListOf no longer treats a
      -- table with an empty array part as an empty list (#65).
      expect(isinstance({meta = print}, Json)).to.be_false()
      -- Invalid nested documents are rejected through the recursive
      -- reference.
      expect(isinstance({1, {2, print}}, Json)).to.be_false()
      expect(isinstance({'a', {'b', {'c', print}}}, Json))
        .to.be_false()
    end)

    it('should express a recursive tree over class instances',
        function()
      local Node = llx.class 'LazyTestNode' {
        __init = function(self, value, children)
          self.value = value
          self.children = children or {}
        end,
      }
      local TreeShape
      TreeShape = Protocol{
        value = Integer,
        children = ListOf(Lazy(function() return TreeShape end)),
      }
      local leaf = Node(1)
      local tree = Node(2, {leaf, Node(3, {Node(4)})})
      expect(isinstance(leaf, TreeShape)).to.be_true()
      expect(isinstance(tree, TreeShape)).to.be_true()
      local bad = Node(5, {Node('six')})
      expect(isinstance(bad, TreeShape)).to.be_false()
    end)
  end)

  describe('is_subtype', function()
    it('should force the subtype side', function()
      expect(is_subtype(Lazy(function() return Integer end), Number))
        .to.be_true()
      expect(is_subtype(Lazy(function() return String end), Number))
        .to.be_false()
    end)

    it('should force the supertype side', function()
      expect(is_subtype(Integer, Lazy(function() return Number end)))
        .to.be_true()
      expect(is_subtype(Number, Lazy(function() return Integer end)))
        .to.be_false()
    end)

    it('should treat a Lazy as equal to its resolved matcher',
        function()
      local L = Lazy(function() return Integer end)
      expect(is_subtype(L, Integer)).to.be_true()
      expect(is_subtype(Integer, L)).to.be_true()
      expect(is_subtype(L, L)).to.be_true()
    end)

    it('should resolve Lazy union members through recursion',
        function()
      local U = Union{Lazy(function() return Integer end), String}
      expect(is_subtype(Integer, U)).to.be_true()
      expect(is_subtype(U, Union{Number, String})).to.be_true()
    end)
  end)

  describe('composition', function()
    it('should compose inside Signature params', function()
      local Element
      local wrapped = signature.Function{
        params = {Lazy(function() return Element end)},
        returns = {String},
        func = function(x) return tostring(x) end,
      }
      Element = Integer
      expect(Callable({Integer}, {String}):__isinstance(wrapped))
        .to.be_true()
      expect(Callable({String}, {String}):__isinstance(wrapped))
        .to.be_false()
    end)

    it('should compose inside Callable params', function()
      local C = Callable({Lazy(function() return Integer end)},
                         {String})
      local wrapped = signature.Function{
        params = {Integer},
        returns = {String},
        func = function(x) return tostring(x) end,
      }
      expect(C:__isinstance(wrapped)).to.be_true()
    end)

    it('should compose inside Tuple', function()
      local Pair = Tuple{Integer, Lazy(function() return String end)}
      expect(isinstance({1, 'one'}, Pair)).to.be_true()
      expect(isinstance({1, 2}, Pair)).to.be_false()
    end)
  end)

  describe('Schema integration', function()
    it('should forward per-type constraint validation', function()
      local schema = Schema{
        type = Lazy(function() return Number end),
        minimum = 2,
      }
      expect(isinstance(3, schema)).to.be_true()
      expect(isinstance(1, schema)).to.be_false()
      expect(isinstance('three', schema)).to.be_false()
    end)

    it('should express a recursive schema', function()
      local TreeSchema
      TreeSchema = Schema{
        type = Table,
        properties = {
          value = {type = Number},
          left = {type = Lazy(function() return TreeSchema end)},
          right = {type = Lazy(function() return TreeSchema end)},
        },
        required = {'value'},
      }
      expect(isinstance({value = 1}, TreeSchema)).to.be_true()
      expect(isinstance({
        value = 1,
        left = {value = 2},
        right = {value = 3, left = {value = 4}},
      }, TreeSchema)).to.be_true()
      expect(isinstance({value = 'one'}, TreeSchema)).to.be_false()
      expect(isinstance({
        value = 1,
        left = {value = 2, right = {value = 'three'}},
      }, TreeSchema)).to.be_false()
      expect(isinstance({left = {value = 2}}, TreeSchema))
        .to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.Lazy', function()
      expect(llx.Lazy).to.be_equal_to(Lazy)
    end)

    it('should export resolve_lazy as llx.resolve_lazy', function()
      expect(llx.resolve_lazy).to.be_equal_to(resolve_lazy)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- TypeVar
-- ---------------------------------------------------------------------------

describe('TypeVar', function()
  local TypeVar = matchers.TypeVar
  local is_type_var = matchers.is_type_var
  local enter_type_var_scope = matchers.enter_type_var_scope
  local exit_type_var_scope = matchers.exit_type_var_scope
  local Float = llx.Float

  describe('construction', function()
    it('should require a string name', function()
      local ok, err = pcall(TypeVar, 42)
      expect(ok).to.be_false()
      expect(tostring(err):find('expected a string name', 1, true))
        .to_not.be_nil()
    end)

    it('should reject a non-table options argument', function()
      local ok = pcall(TypeVar, 'T', 'bound')
      expect(ok).to.be_false()
    end)

    it('should reject unknown options', function()
      local ok, err = pcall(TypeVar, 'T', {covariant = true})
      expect(ok).to.be_false()
      expect(tostring(err):find('unknown option', 1, true))
        .to_not.be_nil()
    end)

    it('should reject a bound without __isinstance', function()
      local ok, err = pcall(TypeVar, 'T', {bound = {}})
      expect(ok).to.be_false()
      expect(tostring(err):find('bound must be', 1, true))
        .to_not.be_nil()
    end)

    it('should expose its name via __name and tostring', function()
      local T = TypeVar('T')
      expect(T.__name).to.be_equal_to('T')
      expect(tostring(T)).to.be_equal_to('T')
    end)

    it('should expose its bound for introspection', function()
      local N = TypeVar('N', {bound = Number})
      expect(N.bound).to.be_equal_to(Number)
      expect(TypeVar('T').bound).to.be_nil()
    end)
  end)

  describe('is_type_var', function()
    it('should recognize TypeVars', function()
      expect(is_type_var(TypeVar('T'))).to.be_true()
    end)

    it('should reject non-TypeVars', function()
      expect(is_type_var(Integer)).to.be_false()
      expect(is_type_var('T')).to.be_false()
      expect(is_type_var(nil)).to.be_false()
      expect(is_type_var({__name = 'T'})).to.be_false()
    end)
  end)

  describe('plain isinstance (no active binding scope)', function()
    it('should accept any value when unconstrained', function()
      local T = TypeVar('T')
      expect(isinstance(1, T)).to.be_true()
      expect(isinstance('s', T)).to.be_true()
      expect(isinstance(nil, T)).to.be_true()
      expect(isinstance({}, T)).to.be_true()
    end)

    it('should behave as its bound when one is declared', function()
      local N = TypeVar('N', {bound = Number})
      expect(isinstance(1, N)).to.be_true()
      expect(isinstance(1.5, N)).to.be_true()
      expect(isinstance('s', N)).to.be_false()
    end)
  end)

  describe('binding scopes', function()
    it('should bind to the first witness and require consistency',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance(1, T)).to.be_true()
      expect(isinstance(2, T)).to.be_true()
      expect(isinstance('s', T)).to.be_false()
      expect(scope[T]).to.be_equal_to(Integer)
      exit_type_var_scope()
    end)

    it('should bind numbers narrowly (Integer vs Float)', function()
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(1, T)).to.be_true()
      expect(isinstance(1.5, T)).to.be_false()
      exit_type_var_scope()
      local scope = enter_type_var_scope()
      expect(isinstance(1.5, T)).to.be_true()
      expect(isinstance(1, T)).to.be_false()
      expect(scope[T]).to.be_equal_to(Float)
      exit_type_var_scope()
    end)

    it('should key bindings by identity, not by name', function()
      local T1 = TypeVar('T')
      local T2 = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(1, T1)).to.be_true()
      -- A distinct variable with the same name is independent.
      expect(isinstance('s', T2)).to.be_true()
      expect(isinstance('s', T1)).to.be_false()
      exit_type_var_scope()
    end)

    it('should enforce the bound on every occurrence', function()
      -- The inferred binding for a plain table is Table, which is
      -- coarser than the structural bound; a later table missing the
      -- bound's shape must still be rejected.
      local Named = Protocol{name = String}
      local T = TypeVar('T', {bound = Named})
      enter_type_var_scope()
      expect(isinstance({name = 'a'}, T)).to.be_true()
      expect(isinstance({name = 'b'}, T)).to.be_true()
      expect(isinstance({title = 'c'}, T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should accept subclass witnesses of a superclass binding',
        function()
      local class = llx.class
      local Animal = class 'TypeVarScopeAnimal' { }
      local Cat = class 'TypeVarScopeCat' : extends(Animal) { }
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(Animal(), T)).to.be_true()
      expect(isinstance(Cat(), T)).to.be_true()
      exit_type_var_scope()
      -- The reverse order narrows the binding to Cat first.
      enter_type_var_scope()
      expect(isinstance(Cat(), T)).to.be_true()
      expect(isinstance(Animal(), T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should fall back to exact-class identity for values whose '
      .. 'class has no __isinstance', function()
      local plain_metatable = {}
      local a = setmetatable({}, plain_metatable)
      local b = setmetatable({}, plain_metatable)
      local c = setmetatable({}, {})
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(a, T)).to.be_true()
      expect(isinstance(b, T)).to.be_true()
      expect(isinstance(c, T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should stay self-consistent for __metatable-protected '
      .. 'values', function()
      -- getmetatable (and therefore getclass) on such a value yields
      -- the protection value, which may not even be a table; the
      -- consistency check must fall back to identity rather than
      -- treating the value as an instance of that string.
      local locked = setmetatable({}, {__metatable = 'locked'})
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(locked, T)).to.be_true()
      expect(isinstance(locked, T)).to.be_true()
      expect(isinstance({}, T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should propagate bindings into parameterized matchers',
        function()
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance({1, 2, 3}, ListOf(T))).to.be_true()
      -- The list's elements bound T to Integer.
      expect(isinstance('s', T)).to.be_false()
      expect(isinstance({4, 5}, ListOf(T))).to.be_true()
      expect(isinstance({'a'}, ListOf(T))).to.be_false()
      exit_type_var_scope()
    end)

    it('should bind nil witnesses to Nil', function()
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance(nil, T)).to.be_true()
      expect(isinstance(nil, T)).to.be_true()
      expect(isinstance(1, T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should raise on exit with no active scope', function()
      local ok, err = pcall(exit_type_var_scope)
      expect(ok).to.be_false()
      expect(tostring(err):find('no active TypeVar binding scope',
                                1, true)).to_not.be_nil()
    end)

    it('should reject a non-table scope argument', function()
      local ok = pcall(enter_type_var_scope, 'scope')
      expect(ok).to.be_false()
    end)
  end)

  describe('speculative branch rollback (Union)', function()
    it('should discard bindings recorded by a failed union branch',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      -- The ListOf branch binds T to Integer from element 1, then
      -- rejects the list at 'x'; the rollback discards the binding
      -- and the Any member accepts.
      expect(isinstance({1, 'x'}, Union{ListOf(T), Any})).to.be_true()
      expect(scope[T]).to.be_nil()
      -- T is still free: a later witness binds from scratch.
      expect(isinstance('s', T)).to.be_true()
      expect(isinstance('t', T)).to.be_true()
      expect(isinstance(1, T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should keep the bindings of a successful union branch',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({1, 2}, Union{ListOf(T), Any})).to.be_true()
      expect(scope[T]).to.be_equal_to(Integer)
      exit_type_var_scope()
    end)

    it('should leave no binding when every branch fails', function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      -- Optional(ListOf(T)) is Union{Nil, ListOf(T)}: the Nil member
      -- rejects, the ListOf member binds T from element 1 and then
      -- rejects; the whole union fails with a clean scope.
      expect(isinstance({1, 'x'}, Optional(ListOf(T)))).to.be_false()
      expect(scope[T]).to.be_nil()
      exit_type_var_scope()
    end)

    it('should restore, not clear, the pre-branch bindings',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      -- T is bound to String before the union runs; the failed
      -- ListOf branch must restore that binding, not erase it.
      expect(isinstance('s', T)).to.be_true()
      expect(isinstance({1, 'x'}, Union{ListOf(T), Any})).to.be_true()
      expect(scope[T]).to.be_equal_to(llx.String)
      exit_type_var_scope()
    end)

    it('should work with no active binding scope', function()
      local T = TypeVar('T')
      expect(isinstance({1, 'x'}, Union{ListOf(T), Any})).to.be_true()
      expect(isinstance(42, Union{String, Boolean})).to.be_false()
    end)
  end)

  describe('commutative witness joins (Dict, SetOf)', function()
    local class = llx.class
    local Animal = class 'TypeVarJoinAnimal' { }
    local Cat = class 'TypeVarJoinCat' : extends(Animal) { }
    local Dog = class 'TypeVarJoinDog' : extends(Animal) { }

    it('should bind the common superclass of a subclass-'
      .. 'heterogeneous Dict, in any iteration order', function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({a = Animal(), b = Cat()}, Dict(String, T)))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Animal)
      exit_type_var_scope()
    end)

    it('should join sibling classes at their common ancestor',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      -- Neither Cat nor Dog admits the other, so first-witness
      -- semantics would reject this in every order; the join binds
      -- their nearest common declared ancestor.
      expect(isinstance({a = Cat(), b = Dog()}, Dict(String, T)))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Animal)
      exit_type_var_scope()
    end)

    it('should join Integer and Float witnesses at Number', function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({a = 1, b = 1.5}, Dict(String, T)))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Number)
      -- The widened binding constrains later positions as usual.
      expect(isinstance(2, T)).to.be_true()
      expect(isinstance('s', T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should reject elements with no join, in any order', function()
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance({a = 1, b = 'x'}, Dict(String, T)))
        .to.be_false()
      exit_type_var_scope()
    end)

    it('should join a class instance and a plain table at Table',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({a = Animal(), b = {}}, Dict(String, T)))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Table)
      exit_type_var_scope()
    end)

    it('should reject unrelated plain-metatable elements, in any '
      .. 'order', function()
      -- Two distinct plain metatables share no declared ancestry,
      -- and their values might not even be tables (a metatable does
      -- not say what it is attached to), so there is no sound join.
      local T = TypeVar('T')
      local obj_a = setmetatable({}, {})
      local obj_b = setmetatable({}, {})
      enter_type_var_scope()
      expect(isinstance({a = obj_a, b = obj_b}, Dict(String, T)))
        .to.be_false()
      exit_type_var_scope()
    end)

    it('should apply the join to SetOf elements', function()
      local Set = llx.Set
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance(Set{Cat(), Animal(), Dog()}, SetOf(T)))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Animal)
      exit_type_var_scope()
    end)

    it('should keep first-witness semantics in ipairs-ordered '
      .. 'containers', function()
      -- List order is part of the value, so ListOf stays one-pass:
      -- a superclass witness admits later subclass elements, but not
      -- the reverse.
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance({Animal(), Cat()}, ListOf(T))).to.be_true()
      exit_type_var_scope()
      enter_type_var_scope()
      expect(isinstance({Cat(), Animal()}, ListOf(T))).to.be_false()
      exit_type_var_scope()
    end)

    it('should extend the join through containers nested inside a '
      .. 'pairs-iterated container', function()
      -- The outer pairs order decides which nested list is checked
      -- first, so order-independence requires joining across (and
      -- therefore within) the nested lists too, even though a bare
      -- ListOf(T) is positional and would reject a mixed list.
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({a = {1, 1.5}}, Dict(String, ListOf(T))))
        .to.be_true()
      expect(scope[T]).to.be_equal_to(Number)
      exit_type_var_scope()
      local T2 = TypeVar('T')
      local scope2 = enter_type_var_scope()
      expect(isinstance({a = {Cat()}, b = {Animal()}},
                        Dict(String, ListOf(T2)))).to.be_true()
      expect(scope2[T2]).to.be_equal_to(Animal)
      exit_type_var_scope()
      -- Outside a pairs-iterated container, ListOf stays one-pass.
      enter_type_var_scope()
      expect(isinstance({1, 1.5}, ListOf(T))).to.be_false()
      exit_type_var_scope()
    end)

    it('should join a multiple-inheritance witness set at the '
      .. 'ancestor common to all witnesses', function()
      local X = class 'TypeVarJoinMixinX' { }
      local Y = class 'TypeVarJoinMixinY' { }
      local A = class 'TypeVarJoinLeafA' : extends(X, Y) { }
      local B = class 'TypeVarJoinLeafB' : extends(X, Y) { }
      local C = class 'TypeVarJoinLeafC' : extends(Y) { }
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      -- Y is the only ancestor common to all three witnesses. The
      -- join is computed over the whole witness set, so it lands on
      -- Y in every iteration order; a pairwise fold could have
      -- tie-broken A and B at X first and then drifted to Table.
      expect(isinstance({a = A(), b = B(), c = C()},
                        Dict(String, T))).to.be_true()
      expect(scope[T]).to.be_equal_to(Y)
      exit_type_var_scope()
      -- The same set presented in explicitly reversed encounter
      -- order reaches the same join.
      local T2 = TypeVar('T')
      local scope2 = enter_type_var_scope()
      expect(isinstance({a = C()}, Dict(String, T2))).to.be_true()
      expect(isinstance({a = B()}, Dict(String, T2))).to.be_true()
      expect(isinstance({a = A()}, Dict(String, T2))).to.be_true()
      expect(scope2[T2]).to.be_equal_to(Y)
      exit_type_var_scope()
    end)

    it('should reach the same join in either encounter order',
        function()
      -- pairs order cannot be forced from a test, so the fold is
      -- driven explicitly: successive single-element containers in
      -- one scope present the witnesses in a chosen order. Both
      -- orders must accept and bind the same join.
      local T1 = TypeVar('T')
      local scope1 = enter_type_var_scope()
      expect(isinstance({a = Cat()}, Dict(String, T1))).to.be_true()
      expect(isinstance({a = Animal()}, Dict(String, T1)))
        .to.be_true()
      expect(scope1[T1]).to.be_equal_to(Animal)
      exit_type_var_scope()
      local T2 = TypeVar('T')
      local scope2 = enter_type_var_scope()
      expect(isinstance({a = Animal()}, Dict(String, T2))).to.be_true()
      expect(isinstance({a = Cat()}, Dict(String, T2))).to.be_true()
      expect(scope2[T2]).to.be_equal_to(Animal)
      exit_type_var_scope()
      -- Sibling classes, both orders join at the common ancestor.
      local T3 = TypeVar('T')
      local scope3 = enter_type_var_scope()
      expect(isinstance({a = Dog()}, Dict(String, T3))).to.be_true()
      expect(isinstance({a = Cat()}, Dict(String, T3))).to.be_true()
      expect(scope3[T3]).to.be_equal_to(Animal)
      exit_type_var_scope()
    end)

    it('should restore a binding widened by a failed union branch',
        function()
      local T = TypeVar('T')
      local scope = enter_type_var_scope()
      expect(isinstance({a = Cat()}, Dict(String, T))).to.be_true()
      expect(scope[T]).to.be_equal_to(Cat)
      -- The Dict member may widen T to Animal before rejecting the
      -- value at 'x' (depending on iteration order); either way the
      -- union rollback restores the original Cat binding.
      expect(isinstance({a = Animal(), b = 'x'},
                        Union{Dict(String, T), Any})).to.be_true()
      expect(scope[T]).to.be_equal_to(Cat)
      exit_type_var_scope()
    end)

    it('should not leak join semantics past the container check',
        function()
      local T = TypeVar('T')
      enter_type_var_scope()
      expect(isinstance({a = Cat()}, Dict(String, T))).to.be_true()
      -- Outside the container, consistency is positional again: an
      -- Animal is not admitted by (or joined into) the Cat binding.
      expect(isinstance(Animal(), T)).to.be_false()
      exit_type_var_scope()
    end)

    it('should work with no active binding scope', function()
      local T = TypeVar('T')
      expect(isinstance({a = Animal(), b = Cat()}, Dict(String, T)))
        .to.be_true()
      expect(isinstance({a = 1, b = 'x'}, Dict(String, Integer)))
        .to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.TypeVar', function()
      expect(llx.TypeVar).to.be_equal_to(TypeVar)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Iterator
-- ---------------------------------------------------------------------------

describe('Iterator', function()
  local typed_iterators = require 'llx.typed_iterators'
  local Yields = typed_iterators.Yields
  local Generates = typed_iterators.Generates

  local function counter(n)
    local i = 0
    return function()
      i = i + 1
      if i <= n then return i end
    end
  end

  describe('__name', function()
    it('should expose an Iterator<yields> name', function()
      expect(Iterator(Integer, String).__name)
        .to.be_equal_to('Iterator<Integer, String>')
      expect(tostring(Iterator(Integer)))
        .to.be_equal_to('Iterator<Integer>')
    end)

    it('should handle an empty yield list', function()
      expect(Iterator().__name).to.be_equal_to('Iterator<>')
    end)

    it('should render a variadic tail as ..., not String', function()
      expect(Iterator(Integer, VARARG).__name)
        .to.be_equal_to('Iterator<Integer, ...>')
    end)
  end)

  describe('construction', function()
    it('should expose the yield types for introspection', function()
      local I = Iterator(Integer, String)
      expect(I.yields[1]).to.be_equal_to(Integer)
      expect(I.yields[2]).to.be_equal_to(String)
    end)

    it('should reject a non-trailing VARARG', function()
      expect(function() Iterator(VARARG, Integer) end)
        .to.throw("Iterator: VARARG ('...') must be the last entry "
          .. 'in the yield type list')
    end)

    it('should reject a nil yield type', function()
      expect(function() Iterator(nil, Integer) end)
        .to.throw('Iterator: yield type 1 is nil')
    end)
  end)

  describe('raw functions and callables (structural)', function()
    it('should accept any function', function()
      -- Raw functions carry no per-step type information; the
      -- structural check is the documented weak fallback.
      local I = Iterator(Integer)
      expect(I:__isinstance(function() end)).to.be_true()
      expect(I:__isinstance(counter(3))).to.be_true()
    end)

    it('should accept a callable table', function()
      local callable = setmetatable({}, {__call = function() end})
      expect(Iterator(Integer):__isinstance(callable)).to.be_true()
    end)

    it('should reject non-callable values', function()
      local I = Iterator(Integer)
      expect(I:__isinstance(42)).to.be_false()
      expect(I:__isinstance('iter')).to.be_false()
      expect(I:__isinstance({})).to.be_false()
      expect(I:__isinstance(nil)).to.be_false()
    end)

    it('should reject bare coroutine threads', function()
      -- generic-for cannot drive a thread directly.
      local thread = coroutine.create(function() end)
      expect(Iterator(Integer):__isinstance(thread)).to.be_false()
    end)
  end)

  describe('wrapped iterators (declared yields)', function()
    it('should match a wrapper with identical yields', function()
      local wrapped = Yields{Integer} .. counter(3)
      expect(isinstance(wrapped, Iterator(Integer))).to.be_true()
    end)

    it('should compare yields covariantly', function()
      local wrapped = Yields{Integer} .. counter(3)
      expect(isinstance(wrapped, Iterator(Number))).to.be_true()
      expect(isinstance(wrapped, Iterator(String))).to.be_false()
    end)

    it('should require matching yield arity', function()
      local wrapped = Yields{Integer} .. counter(3)
      expect(isinstance(wrapped, Iterator(Integer, String)))
        .to.be_false()
    end)

    it('should apply variadic arity rules to declared '
      .. 'yields', function()
      -- A fixed wrapper satisfies a variadic matcher whose fixed
      -- prefix it covers; a variadic wrapper may produce undeclared
      -- extras a fixed matcher's consumers would observe.
      local fixed = Yields{Integer, String} .. counter(0)
      expect(isinstance(fixed, Iterator(Integer, VARARG)))
        .to.be_true()
      local variadic = Yields{Integer, VARARG} .. counter(0)
      expect(isinstance(variadic, Iterator(Integer))).to.be_false()
      expect(isinstance(variadic, Iterator(Integer, VARARG)))
        .to.be_true()
    end)

    it('should match typed generators by their yields', function()
      local gen = Generates{yields = {Integer}} .. function()
        coroutine.yield(1)
      end
      local instance = gen()
      expect(isinstance(instance, Iterator(Integer))).to.be_true()
      expect(isinstance(instance, Iterator(Number))).to.be_true()
      expect(isinstance(instance, Iterator(String))).to.be_false()
    end)

    it('should reject typed generators that declare return '
      .. 'values', function()
      -- A generator whose body may return values on completion is
      -- not generic-for terminable: the loop would consume the
      -- return values as a step and then resume a dead coroutine.
      local gen = Generates{yields = {Integer}, returns = {String}}
          .. function()
        coroutine.yield(1)
        return 'done'
      end
      expect(isinstance(gen(), Iterator(Integer))).to.be_false()
    end)
  end)

  describe('composition', function()
    it('should compose inside Protocol', function()
      local Iterable = Protocol{iter = Iterator(Integer)}
      local good = {iter = Yields{Integer} .. counter(2)}
      local bad = {iter = Yields{String} .. counter(2)}
      local missing = {}
      expect(isinstance(good, Iterable)).to.be_true()
      expect(isinstance(bad, Iterable)).to.be_false()
      expect(isinstance(missing, Iterable)).to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.Iterator', function()
      expect(llx.Iterator).to.be_equal_to(Iterator)
    end)
  end)
end)

-- ---------------------------------------------------------------------------
-- Generator
-- ---------------------------------------------------------------------------

describe('Generator', function()
  local typed_iterators = require 'llx.typed_iterators'
  local Generates = typed_iterators.Generates

  local function typed_gen(contract)
    return (Generates(contract) .. function()
      coroutine.yield(1)
    end)()
  end

  describe('__name', function()
    it('should encode the full contract in the name', function()
      local G = Generator{yields = {Integer}, accepts = {String},
                          returns = {Boolean}}
      expect(G.__name).to.be_equal_to(
        'Generator<yields=(Integer), accepts=(String), '
        .. 'returns=(Boolean)>')
    end)

    it('should default missing lists to empty', function()
      expect(Generator{}.__name).to.be_equal_to(
        'Generator<yields=(), accepts=(), returns=()>')
      expect(Generator().__name).to.be_equal_to(
        'Generator<yields=(), accepts=(), returns=()>')
    end)
  end)

  describe('construction', function()
    it('should expose the contract for introspection', function()
      local yields, accepts, returns = {Integer}, {String}, {}
      local G = Generator{yields = yields, accepts = accepts,
                          returns = returns}
      expect(G.yields).to.be_equal_to(yields)
      expect(G.accepts).to.be_equal_to(accepts)
      expect(G.returns).to.be_equal_to(returns)
    end)

    it('should reject unknown contract keys', function()
      expect(function() Generator{sends = {Integer}} end)
        .to.throw("Generator: unknown contract key 'sends'")
    end)
  end)

  describe('plain threads (structural fallback)', function()
    it('should accept any thread, whatever the contract', function()
      -- Documented weak fallback: a raw thread carries no contract,
      -- so only its threadness can be verified.
      local thread = coroutine.create(function() end)
      expect(Generator{yields = {Integer}}:__isinstance(thread))
        .to.be_true()
      expect(Generator{}:__isinstance(thread)).to.be_true()
    end)
  end)

  describe('typed generators (declared contract)', function()
    it('should match an identical contract', function()
      local instance = typed_gen{yields = {Integer}}
      expect(isinstance(instance, Generator{yields = {Integer}}))
        .to.be_true()
    end)

    it('should compare yields covariantly', function()
      local instance = typed_gen{yields = {Integer}}
      expect(isinstance(instance, Generator{yields = {Number}}))
        .to.be_true()
      expect(isinstance(instance, Generator{yields = {String}}))
        .to.be_false()
    end)

    it('should compare accepts contravariantly', function()
      local instance = typed_gen{yields = {Integer},
                                 accepts = {Number}}
      -- The instance accepts any Number, so it can stand in where
      -- only Integers are promised to be sent...
      expect(isinstance(instance, Generator{yields = {Integer},
                                            accepts = {Integer}}))
        .to.be_true()
      -- ...but an Integer-only instance cannot stand in where
      -- callers are promised they may send any Number.
      local narrow = typed_gen{yields = {Integer},
                               accepts = {Integer}}
      expect(isinstance(narrow, Generator{yields = {Integer},
                                          accepts = {Number}}))
        .to.be_false()
    end)

    it('should compare returns covariantly', function()
      local instance = typed_gen{yields = {Integer},
                                 returns = {Integer}}
      expect(isinstance(instance, Generator{yields = {Integer},
                                            returns = {Number}}))
        .to.be_true()
      expect(isinstance(instance, Generator{yields = {Integer},
                                            returns = {String}}))
        .to.be_false()
    end)

    it('should require matching accepts arity', function()
      local instance = typed_gen{yields = {Integer}}
      expect(isinstance(instance, Generator{yields = {Integer},
                                            accepts = {String}}))
        .to.be_false()
    end)
  end)

  describe('rejected values', function()
    it('should reject plain functions and wrap results', function()
      -- coroutine.wrap returns a plain function, indistinguishable
      -- from any other; Iterator or Callable are the right matchers
      -- for it.
      local G = Generator{yields = {Integer}}
      expect(G:__isinstance(function() end)).to.be_false()
      expect(G:__isinstance(coroutine.wrap(function() end)))
        .to.be_false()
    end)

    it('should reject non-coroutine values', function()
      local G = Generator{}
      expect(G:__isinstance(42)).to.be_false()
      expect(G:__isinstance({})).to.be_false()
      expect(G:__isinstance(nil)).to.be_false()
    end)
  end)

  describe('top-level llx namespace', function()
    it('should be exported as llx.Generator', function()
      expect(llx.Generator).to.be_equal_to(Generator)
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
