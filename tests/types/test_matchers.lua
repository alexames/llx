local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'
local signature = require 'llx.signature'

local Any = matchers.Any
local Union = matchers.Union
local Optional = matchers.Optional
local Dict = matchers.Dict
local Protocol = matchers.Protocol
local Callable = matchers.Callable
local Tuple = matchers.Tuple

local TupleValue = require 'llx.tuple' . Tuple

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

  describe('top-level llx namespace', function()
    it('should leave llx.Tuple as the value class', function()
      expect(llx.Tuple).to.be_equal_to(TupleValue)
      expect(tostring(llx.Tuple{1, 2})).to.be_equal_to('Tuple{1,2}')
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

if llx.main_file() then
  unit.run_unit_tests()
end
