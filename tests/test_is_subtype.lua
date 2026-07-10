local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'
local signature = require 'llx.signature'

local is_subtype = require 'llx.is_subtype' . is_subtype
local signature_compatible =
    require 'llx.is_subtype' . signature_compatible
local generator_compatible =
    require 'llx.is_subtype' . generator_compatible
local VARARG = require 'llx.check_arguments' . VARARG

local Any = matchers.Any
local Never = matchers.Never
local Union = matchers.Union
local Optional = matchers.Optional
local Dict = matchers.Dict
local Callable = matchers.Callable
local AnyParams = matchers.AnyParams
local Tuple = matchers.Tuple
local Rest = matchers.Rest
local Lazy = matchers.Lazy

local class = llx.class
local Float = llx.Float
local Integer = llx.Integer
local Number = llx.Number
local String = llx.String
local isinstance = llx.isinstance

local Animal = class 'Animal' { }
local Cat = class 'Cat' : extends(Animal) { }
local Kitten = class 'Kitten' : extends(Cat) { }
local Dog = class 'Dog' : extends(Animal) { }

_ENV = unit.create_test_env(_ENV)

describe('is_subtype', function()
  describe('reflexivity and equality', function()
    it('should be reflexive for built-in type matchers', function()
      expect(is_subtype(String, String)).to.be_true()
      expect(is_subtype(Integer, Integer)).to.be_true()
    end)

    it('should be reflexive for classes', function()
      expect(is_subtype(Animal, Animal)).to.be_true()
    end)

    it('should treat structurally equal matchers as equal '
      .. 'by name', function()
      local a = Dict(String, Integer)
      local b = Dict(String, Integer)
      expect(is_subtype(a, b)).to.be_true()
    end)

    it('should match string type names against matcher names', function()
      expect(is_subtype('Integer', Integer)).to.be_true()
      expect(is_subtype(String, 'String')).to.be_true()
      expect(is_subtype('Integer', String)).to.be_false()
    end)

    it('should return false for nil arguments', function()
      expect(is_subtype(nil, String)).to.be_false()
      expect(is_subtype(String, nil)).to.be_false()
    end)
  end)

  describe('Any as top type', function()
    it('should treat every type as a subtype of Any', function()
      expect(is_subtype(String, Any)).to.be_true()
      expect(is_subtype(Integer, Any)).to.be_true()
      expect(is_subtype(Animal, Any)).to.be_true()
      expect(is_subtype(Union{String, Integer}, Any)).to.be_true()
      expect(is_subtype(Any, Any)).to.be_true()
    end)

    it('should not treat Any as a subtype of a narrower type', function()
      expect(is_subtype(Any, String)).to.be_false()
      expect(is_subtype(Any, Animal)).to.be_false()
    end)
  end)

  describe('class hierarchies', function()
    it('should accept a direct subclass', function()
      expect(is_subtype(Cat, Animal)).to.be_true()
    end)

    it('should reject the reverse direction', function()
      expect(is_subtype(Animal, Cat)).to.be_false()
    end)

    it('should walk the hierarchy transitively', function()
      expect(is_subtype(Kitten, Cat)).to.be_true()
      expect(is_subtype(Kitten, Animal)).to.be_true()
    end)

    it('should reject unrelated siblings', function()
      expect(is_subtype(Cat, Dog)).to.be_false()
      expect(is_subtype(Dog, Cat)).to.be_false()
    end)

    it('should support multiple inheritance', function()
      local Swimmer = class 'Swimmer' { }
      local Flyer = class 'Flyer' { }
      local Duck = class 'Duck' : extends(Swimmer, Flyer) { }
      expect(is_subtype(Duck, Swimmer)).to.be_true()
      expect(is_subtype(Duck, Flyer)).to.be_true()
      expect(is_subtype(Swimmer, Flyer)).to.be_false()
    end)

    it('should compare distinct anonymous classes '
      .. 'by identity only', function()
      local A = class { }
      local B = class { }
      expect(is_subtype(A, A)).to.be_true()
      expect(is_subtype(A, B)).to.be_false()
    end)
  end)

  describe('Union', function()
    it('should accept a member as a subtype of the union', function()
      expect(is_subtype(Integer, Union{Integer, String})).to.be_true()
      expect(is_subtype(String, Union{Integer, String})).to.be_true()
    end)

    it('should accept a subtype of a member', function()
      expect(is_subtype(Cat, Union{Animal, String})).to.be_true()
      expect(is_subtype(Integer, Union{Number, String})).to.be_true()
    end)

    it('should reject a non-member', function()
      expect(is_subtype(Float, Union{Integer, String})).to.be_false()
    end)

    it('should not treat a union as a subtype of a member', function()
      expect(is_subtype(Union{Integer, String}, Integer)).to.be_false()
    end)

    it('should accept a union whose members are all subtypes', function()
      expect(is_subtype(Union{Integer, Float}, Number)).to.be_true()
      expect(is_subtype(Union{Cat, Dog}, Animal)).to.be_true()
    end)

    it('should relate two unions memberwise', function()
      expect(is_subtype(Union{Integer, String},
                        Union{String, Number})).to.be_true()
      expect(is_subtype(Union{Integer, Animal},
                        Union{Number, String})).to.be_false()
    end)

    it('should treat Optional as Union with Nil', function()
      expect(is_subtype(String, Optional(String))).to.be_true()
      expect(is_subtype(Integer, Optional(String))).to.be_false()
    end)
  end)

  describe('numeric widening', function()
    it('should treat Integer as a subtype of Number', function()
      expect(is_subtype(Integer, Number)).to.be_true()
    end)

    it('should treat Float as a subtype of Number', function()
      expect(is_subtype(Float, Number)).to.be_true()
    end)

    it('should not widen in the other direction', function()
      expect(is_subtype(Number, Integer)).to.be_false()
      expect(is_subtype(Number, Float)).to.be_false()
    end)

    it('should not relate Integer and Float to each other', function()
      expect(is_subtype(Integer, Float)).to.be_false()
      expect(is_subtype(Float, Integer)).to.be_false()
    end)
  end)

  describe('NewType brands', function()
    local NewType = matchers.NewType

    it('should treat a brand as a subtype of its base', function()
      local UserId = NewType('UserId', Integer)
      expect(is_subtype(UserId, Integer)).to.be_true()
    end)

    it('should widen transitively through the base', function()
      local UserId = NewType('UserId', Integer)
      expect(is_subtype(UserId, Number)).to.be_true()
      expect(is_subtype(UserId, Any)).to.be_true()
    end)

    it('should not widen from base to brand', function()
      local UserId = NewType('UserId', Integer)
      expect(is_subtype(Integer, UserId)).to.be_false()
    end)

    it('should keep sibling brands unrelated', function()
      local UserId = NewType('UserId', Integer)
      local OrderId = NewType('OrderId', Integer)
      expect(is_subtype(UserId, OrderId)).to.be_false()
      expect(is_subtype(OrderId, UserId)).to.be_false()
    end)

    it('should chain through nested brands', function()
      local UserId = NewType('UserId', Integer)
      local AdminId = NewType('AdminId', UserId)
      expect(is_subtype(AdminId, UserId)).to.be_true()
      expect(is_subtype(AdminId, Integer)).to.be_true()
      expect(is_subtype(UserId, AdminId)).to.be_false()
    end)

    it('should be a subtype of a Union containing the brand '
      .. 'or its base', function()
      local UserId = NewType('UserId', Integer)
      expect(is_subtype(UserId, Union{UserId, String})).to.be_true()
      expect(is_subtype(UserId, Union{Integer, String})).to.be_true()
      expect(is_subtype(UserId, Union{String})).to.be_false()
    end)
  end)

  describe('Never as bottom type', function()
    it('should treat Never as a subtype of every type', function()
      expect(is_subtype(Never, Integer)).to.be_true()
      expect(is_subtype(Never, String)).to.be_true()
      expect(is_subtype(Never, Animal)).to.be_true()
      expect(is_subtype(Never, Any)).to.be_true()
      expect(is_subtype(Never, Union{Integer, String})).to.be_true()
      expect(is_subtype(Never, Never)).to.be_true()
    end)

    it('should not treat other types as subtypes of Never', function()
      expect(is_subtype(Integer, Never)).to.be_false()
      expect(is_subtype(Any, Never)).to.be_false()
      expect(is_subtype(Animal, Never)).to.be_false()
      expect(is_subtype(Union{Integer}, Never)).to.be_false()
    end)

    it('should accept uninhabited unions as subtypes '
      .. 'of Never', function()
      expect(is_subtype(Union{}, Never)).to.be_true()
      expect(is_subtype(Union{Never}, Never)).to.be_true()
      expect(is_subtype(Union{Never, Integer}, Never)).to.be_false()
    end)

    it('should keep TypeVars excluded even against Never', function()
      -- TypeVar exclusion takes precedence: type variables stay out
      -- of the variance relation entirely (see the TypeVar tests
      -- below), so not even Never relates to one.
      local T = matchers.TypeVar('T')
      expect(is_subtype(Never, T)).to.be_false()
      expect(is_subtype(T, Never)).to.be_false()
    end)
  end)

  describe('Tuple structural rules', function()
    it('should compare fixed tuples element-wise '
      .. 'covariantly', function()
      expect(is_subtype(Tuple{Integer}, Tuple{Number})).to.be_true()
      expect(is_subtype(Tuple{Number}, Tuple{Integer})).to.be_false()
      expect(is_subtype(Tuple{Cat, Integer},
                        Tuple{Animal, Number})).to.be_true()
      expect(is_subtype(Tuple{Animal, Integer},
                        Tuple{Cat, Number})).to.be_false()
    end)

    it('should accept separately constructed identical '
      .. 'tuples', function()
      expect(is_subtype(Tuple{Integer, String},
                        Tuple{Integer, String})).to.be_true()
      expect(is_subtype(Tuple{Rest(Integer)},
                        Tuple{Rest(Integer)})).to.be_true()
    end)

    it('should require equal arity between fixed tuples', function()
      expect(is_subtype(Tuple{Integer},
                        Tuple{Integer, Integer})).to.be_false()
      expect(is_subtype(Tuple{Integer, Integer},
                        Tuple{Integer})).to.be_false()
    end)

    it('should accept a fixed tuple under a Rest-variadic '
      .. 'tuple', function()
      expect(is_subtype(Tuple{Integer, Integer},
                        Tuple{Integer, Rest(Integer)})).to.be_true()
      expect(is_subtype(Tuple{Integer, Integer},
                        Tuple{Rest(Integer)})).to.be_true()
      expect(is_subtype(Tuple{}, Tuple{Rest(Integer)})).to.be_true()
      expect(is_subtype(Tuple{Integer, String},
                        Tuple{Rest(Integer)})).to.be_false()
    end)

    it('should reject a fixed tuple shorter than a variadic '
      .. 'prefix', function()
      expect(is_subtype(
          Tuple{Integer},
          Tuple{Integer, Integer, Rest(Integer)})).to.be_false()
    end)

    it('should compare Rest tails covariantly', function()
      expect(is_subtype(Tuple{Rest(Integer)},
                        Tuple{Rest(Number)})).to.be_true()
      expect(is_subtype(Tuple{Rest(Number)},
                        Tuple{Rest(Integer)})).to.be_false()
      expect(is_subtype(Tuple{String, Rest(Cat)},
                        Tuple{String, Rest(Animal)})).to.be_true()
    end)

    it('should not accept a variadic tuple where a fixed one '
      .. 'is expected', function()
      expect(is_subtype(Tuple{Rest(Integer)},
                        Tuple{Integer})).to.be_false()
      expect(is_subtype(Tuple{Integer, VARARG},
                        Tuple{Integer})).to.be_false()
    end)

    it('should treat an unchecked tail as a tail of Any', function()
      expect(is_subtype(Tuple{Integer}, Tuple{VARARG})).to.be_true()
      expect(is_subtype(Tuple{Rest(Integer)},
                        Tuple{VARARG})).to.be_true()
      expect(is_subtype(Tuple{Integer, VARARG},
                        Tuple{Integer, VARARG})).to.be_true()
      -- The unchecked tail admits anything, so only a tail that
      -- admits Any can stand above it.
      expect(is_subtype(Tuple{Integer, VARARG},
                        Tuple{Rest(Integer)})).to.be_false()
      expect(is_subtype(Tuple{Integer, VARARG},
                        Tuple{Rest(Any)})).to.be_true()
    end)

    it('should let the structural verdict beat name '
      .. 'equality', function()
      -- Two tuples over distinct same-named classes spell the same
      -- __name; structure (class identity) decides, not the name.
      local C1 = class 'TupleCollide' { }
      local C2 = class 'TupleCollide' { }
      expect(is_subtype(Tuple{C1}, Tuple{C1})).to.be_true()
      expect(is_subtype(Tuple{C1}, Tuple{C2})).to.be_false()
    end)

    it('should relate tuples to Any and Union normally', function()
      expect(is_subtype(Tuple{Integer}, Any)).to.be_true()
      expect(is_subtype(Tuple{Integer},
                        Union{Tuple{Number}, String})).to.be_true()
      expect(is_subtype(Tuple{Integer},
                        Union{Tuple{String}, String})).to.be_false()
    end)
  end)

  describe('name-collision identity for classes', function()
    it('should keep distinct classes sharing a name '
      .. 'unrelated', function()
      local A1 = class 'SameName' { }
      local A2 = class 'SameName' { }
      expect(is_subtype(A1, A1)).to.be_true()
      expect(is_subtype(A2, A2)).to.be_true()
      expect(is_subtype(A1, A2)).to.be_false()
      expect(is_subtype(A2, A1)).to.be_false()
    end)

    it('should relate a subclass to its own base only', function()
      local B1 = class 'SameBase' { }
      local B2 = class 'SameBase' { }
      local Derived = class 'Derived' : extends(B1) { }
      expect(is_subtype(Derived, B1)).to.be_true()
      expect(is_subtype(Derived, B2)).to.be_false()
    end)

    it('should still match string names against classes '
      .. 'by name', function()
      local C1 = class 'StringNamed' { }
      local C2 = class 'StringNamed' { }
      expect(is_subtype('StringNamed', C1)).to.be_true()
      expect(is_subtype('StringNamed', C2)).to.be_true()
      expect(is_subtype(C1, 'StringNamed')).to.be_true()
    end)

    it('should keep name equality for parameterized '
      .. 'matchers', function()
      -- Separately constructed matchers rely on the name rule by
      -- design; only llx classes carry identity.
      expect(is_subtype(Dict(String, Integer),
                        Dict(String, Integer))).to.be_true()
      local NewType = matchers.NewType
      local N1 = NewType('SameBrand', Integer)
      local N2 = NewType('SameBrand', Integer)
      expect(is_subtype(N1, N2)).to.be_true()
    end)
  end)

  describe('recursive comparison cycle guard', function()
    it('should raise on a recursive union with no base '
      .. 'case', function()
      local A
      A = Union{Lazy(function() return A end)}
      expect(function() return is_subtype(A, Integer) end)
        .to.throw()
      expect(function() return is_subtype(Integer, A) end)
        .to.throw()
    end)

    it('should name the cycle in the error message', function()
      local A
      A = Union{Lazy(function() return A end)}
      local ok, err = pcall(is_subtype, A, Integer)
      expect(ok).to.be_false()
      expect(string.find(tostring(err),
          'cyclic type comparison', 1, true) ~= nil).to.be_true()
    end)

    it('should raise on mutually recursive unions with no base '
      .. 'case', function()
      local A, B
      A = Union{Lazy(function() return B end)}
      B = Union{Lazy(function() return A end)}
      expect(function() return is_subtype(A, Integer) end)
        .to.throw()
    end)

    it('should raise when the walk reaches a direct self-member, '
      .. 'even beside a base case', function()
      local A
      A = Union{Integer, Lazy(function() return A end)}
      -- The Integer member decides Integer <= A before the self
      -- member is reached; a walk that does reach the self member
      -- depends on itself and raises.
      expect(is_subtype(Integer, A)).to.be_true()
      expect(function() return is_subtype(A, Number) end).to.throw()
    end)

    it('should still resolve recursive types with a base '
      .. 'case', function()
      local ListOf = matchers.ListOf
      local T
      T = Union{Integer, ListOf(Lazy(function() return T end))}
      expect(is_subtype(Integer, T)).to.be_true()
      expect(is_subtype(T, T)).to.be_true()
      expect(is_subtype(T, Integer)).to.be_false()
    end)

    it('should stay reflexive for recursive tuples but raise on '
      .. 'structural comparison of distinct ones', function()
      local T1
      T1 = Tuple{Integer, Rest(Lazy(function() return T1 end))}
      local T2
      T2 = Tuple{Integer, Rest(Lazy(function() return T2 end))}
      expect(is_subtype(T1, T1)).to.be_true()
      -- Deciding T1 <= T2 structurally depends on itself; compare
      -- recursive types by identity instead.
      expect(function() return is_subtype(T1, T2) end).to.throw()
    end)
  end)
end)

describe('signature_compatible', function()
  local function sig(params, returns)
    return {params = params, returns = returns}
  end

  describe('classic variance cases', function()
    it('should accept (Animal) -> Cat where (Cat) -> Animal '
      .. 'is expected', function()
      expect(signature_compatible(
          sig({Animal}, {Cat}),
          sig({Cat}, {Animal}))).to.be_true()
    end)

    it('should reject (Cat) -> Animal where (Animal) -> Cat '
      .. 'is expected', function()
      expect(signature_compatible(
          sig({Cat}, {Animal}),
          sig({Animal}, {Cat}))).to.be_false()
    end)

    it('should accept an identical signature', function()
      expect(signature_compatible(
          sig({Cat}, {Animal}),
          sig({Cat}, {Animal}))).to.be_true()
    end)

    it('should reject contravariant violation in parameters '
      .. 'alone', function()
      expect(signature_compatible(
          sig({Cat}, {Animal}),
          sig({Animal}, {Animal}))).to.be_false()
    end)

    it('should reject covariant violation in returns alone', function()
      expect(signature_compatible(
          sig({Animal}, {Animal}),
          sig({Animal}, {Cat}))).to.be_false()
    end)
  end)

  describe('arity', function()
    it('should require equal parameter counts', function()
      expect(signature_compatible(
          sig({Integer, Integer}, {}),
          sig({Integer}, {}))).to.be_false()
      expect(signature_compatible(
          sig({Integer}, {}),
          sig({Integer, Integer}, {}))).to.be_false()
    end)

    it('should require equal return counts', function()
      expect(signature_compatible(
          sig({}, {Integer, Integer}),
          sig({}, {Integer}))).to.be_false()
      expect(signature_compatible(
          sig({}, {Integer}),
          sig({}, {Integer, Integer}))).to.be_false()
    end)

    it('should accept two empty signatures', function()
      expect(signature_compatible(sig({}, {}), sig({}, {}))).to.be_true()
    end)

    it('should default missing lists to empty', function()
      expect(signature_compatible({}, {})).to.be_true()
      expect(signature_compatible({params = {Integer}}, {}))
        .to.be_false()
    end)

    it('should reject non-table arguments', function()
      expect(signature_compatible(nil, sig({}, {}))).to.be_false()
      expect(signature_compatible(sig({}, {}), 42)).to.be_false()
    end)
  end)

  describe('Any and Union edges', function()
    it('should accept any return where Any is expected', function()
      expect(signature_compatible(
          sig({}, {Cat}),
          sig({}, {Any}))).to.be_true()
    end)

    it('should accept a parameter of Any where a narrower '
      .. 'parameter is expected', function()
      expect(signature_compatible(
          sig({Any}, {}),
          sig({Cat}, {}))).to.be_true()
    end)

    it('should widen parameters through Union', function()
      expect(signature_compatible(
          sig({Union{Integer, String}}, {}),
          sig({Integer}, {}))).to.be_true()
    end)

    it('should narrow returns through Union', function()
      expect(signature_compatible(
          sig({}, {Integer}),
          sig({}, {Union{Integer, String}}))).to.be_true()
    end)

    it('should apply numeric widening covariantly '
      .. 'in returns', function()
      expect(signature_compatible(
          sig({}, {Integer}),
          sig({}, {Number}))).to.be_true()
      expect(signature_compatible(
          sig({}, {Number}),
          sig({}, {Integer}))).to.be_false()
    end)
  end)

  describe('variadic parameters', function()
    it('should accept a variadic sub whose checked prefix is '
      .. 'covered by a fixed super', function()
      expect(signature_compatible(
          sig({Integer, VARARG}, {}),
          sig({Integer, String}, {}))).to.be_true()
    end)

    it('should apply contravariance on the checked prefix', function()
      expect(signature_compatible(
          sig({Animal, VARARG}, {}),
          sig({Cat, String}, {}))).to.be_true()
      expect(signature_compatible(
          sig({Cat, VARARG}, {}),
          sig({Animal}, {}))).to.be_false()
    end)

    it('should reject a variadic sub whose checked prefix extends '
      .. 'past the super parameter list', function()
      expect(signature_compatible(
          sig({Integer, String, VARARG}, {}),
          sig({Integer}, {}))).to.be_false()
    end)

    it('should reject a fixed sub where a variadic super '
      .. 'is expected', function()
      expect(signature_compatible(
          sig({Integer}, {}),
          sig({Integer, VARARG}, {}))).to.be_false()
      expect(signature_compatible(
          sig({}, {}),
          sig({VARARG}, {}))).to.be_false()
    end)

    it('should relate two variadic parameter lists by their '
      .. 'checked prefixes', function()
      expect(signature_compatible(
          sig({Integer, VARARG}, {}),
          sig({Integer, String, VARARG}, {}))).to.be_true()
      expect(signature_compatible(
          sig({Integer, String, VARARG}, {}),
          sig({Integer, VARARG}, {}))).to.be_false()
    end)

    it('should accept an accepts-anything sub everywhere', function()
      expect(signature_compatible(
          sig({VARARG}, {}),
          sig({Integer, String}, {}))).to.be_true()
      expect(signature_compatible(
          sig({VARARG}, {}),
          sig({}, {}))).to.be_true()
      expect(signature_compatible(
          sig({VARARG}, {}),
          sig({Integer, VARARG}, {}))).to.be_true()
    end)

    it('should accept identical variadic signatures', function()
      expect(signature_compatible(
          sig({Integer, VARARG}, {Integer}),
          sig({Integer, VARARG}, {Integer}))).to.be_true()
    end)
  end)

  describe('variadic returns', function()
    it('should reject a variadic sub return list where a fixed '
      .. 'super is expected', function()
      expect(signature_compatible(
          sig({}, {Integer, VARARG}),
          sig({}, {Integer}))).to.be_false()
      expect(signature_compatible(
          sig({}, {VARARG}),
          sig({}, {}))).to.be_false()
    end)

    it('should accept fixed sub returns covering a variadic '
      .. 'super prefix', function()
      expect(signature_compatible(
          sig({}, {Integer, String}),
          sig({}, {Integer, VARARG}))).to.be_true()
    end)

    it('should reject fixed sub returns shorter than a variadic '
      .. 'super prefix', function()
      expect(signature_compatible(
          sig({}, {}),
          sig({}, {Integer, VARARG}))).to.be_false()
    end)

    it('should apply covariance on the promised prefix', function()
      expect(signature_compatible(
          sig({}, {Cat, Dog}),
          sig({}, {Animal, VARARG}))).to.be_true()
      expect(signature_compatible(
          sig({}, {Animal, Dog}),
          sig({}, {Cat, VARARG}))).to.be_false()
    end)

    it('should relate two variadic return lists by their '
      .. 'declared prefixes', function()
      expect(signature_compatible(
          sig({}, {Integer, String, VARARG}),
          sig({}, {Integer, VARARG}))).to.be_true()
      expect(signature_compatible(
          sig({}, {Integer, VARARG}),
          sig({}, {Integer, String, VARARG}))).to.be_false()
    end)
  end)

  describe('malformed variadic declarations', function()
    it('should treat a non-trailing VARARG as compatible '
      .. 'with nothing', function()
      expect(signature_compatible(
          sig({VARARG, Integer}, {}),
          sig({VARARG, Integer}, {}))).to.be_false()
      expect(signature_compatible(
          sig({Integer}, {}),
          sig({VARARG, Integer}, {}))).to.be_false()
      expect(signature_compatible(
          sig({}, {VARARG, Integer}),
          sig({}, {VARARG, Integer}))).to.be_false()
    end)
  end)

  describe('AnyParams escape hatch', function()
    -- AnyParams in place of a parameter list is mypy's
    -- Callable[..., R]: the declaring side does not constrain
    -- parameters at all, so the parameter checks are skipped and
    -- only returns are compared.
    it('should accept any sub parameter list under an AnyParams '
      .. 'super', function()
      expect(signature_compatible(
          sig({Integer, String}, {}),
          sig(AnyParams, {}))).to.be_true()
      expect(signature_compatible(
          sig({}, {}),
          sig(AnyParams, {}))).to.be_true()
      expect(signature_compatible(
          sig({Integer, VARARG}, {}),
          sig(AnyParams, {}))).to.be_true()
    end)

    it('should accept an AnyParams sub against any super '
      .. 'parameter list', function()
      expect(signature_compatible(
          sig(AnyParams, {}),
          sig({Integer, String}, {}))).to.be_true()
      expect(signature_compatible(
          sig(AnyParams, {}),
          sig({}, {}))).to.be_true()
      expect(signature_compatible(
          sig(AnyParams, {}),
          sig({VARARG}, {}))).to.be_true()
    end)

    it('should relate two AnyParams signatures by their '
      .. 'returns', function()
      expect(signature_compatible(
          sig(AnyParams, {Integer}),
          sig(AnyParams, {Number}))).to.be_true()
      expect(signature_compatible(
          sig(AnyParams, {String}),
          sig(AnyParams, {Number}))).to.be_false()
    end)

    it('should still compare returns covariantly', function()
      expect(signature_compatible(
          sig({Integer}, {Cat}),
          sig(AnyParams, {Animal}))).to.be_true()
      expect(signature_compatible(
          sig({Integer}, {Animal}),
          sig(AnyParams, {Cat}))).to.be_false()
      expect(signature_compatible(
          sig({Integer}, {Animal, Animal}),
          sig(AnyParams, {Animal}))).to.be_false()
    end)

    it('should reject a malformed counterpart list', function()
      -- AnyParams accepts every well-formed parameter list, not
      -- broken ones: a non-trailing VARARG stays compatible with
      -- nothing.
      expect(signature_compatible(
          sig({VARARG, Integer}, {}),
          sig(AnyParams, {}))).to.be_false()
      expect(signature_compatible(
          sig(AnyParams, {}),
          sig({VARARG, Integer}, {}))).to.be_false()
    end)

    it('should treat an AnyParams return list as malformed', function()
      expect(signature_compatible(
          sig({}, AnyParams),
          sig({}, {}))).to.be_false()
      expect(signature_compatible(
          sig({}, {}),
          sig({}, AnyParams))).to.be_false()
      expect(signature_compatible(
          sig({}, AnyParams),
          sig({}, AnyParams))).to.be_false()
    end)

    it('should match wrapped functions against '
      .. 'Callable(AnyParams, ...) by returns only', function()
      local wrapped = signature.Function{
        params = {Animal, String},
        returns = {Cat},
        func = function(...) return ... end,
      }
      expect(isinstance(wrapped, Callable(AnyParams, {Animal})))
        .to.be_true()
      expect(isinstance(wrapped, Callable(AnyParams, {String})))
        .to.be_false()
      -- Parameter arity is invisible through AnyParams.
      local zero_arg = signature.Function{
        params = {},
        returns = {Cat},
        func = function() end,
      }
      expect(isinstance(zero_arg, Callable(AnyParams, {Animal})))
        .to.be_true()
    end)

    it('should keep AnyParams and variadic Callables distinct '
      .. 'in is_subtype', function()
      -- Callable({VARARG}, {R}) means "must be variadic";
      -- Callable(AnyParams, {R}) means "parameters unchecked". The
      -- matchers render differently, so the name fallback never
      -- conflates them, while separately constructed AnyParams
      -- matchers still compare equal.
      local any_form = Callable(AnyParams, {String})
      local vararg_form = Callable({VARARG}, {String})
      expect(is_subtype(any_form, vararg_form)).to.be_false()
      expect(is_subtype(vararg_form, any_form)).to.be_false()
      expect(is_subtype(any_form, Callable(AnyParams, {String})))
        .to.be_true()
    end)
  end)

  describe('Callable integration', function()
    local function make_wrapped(params, returns)
      return signature.Function{
        params = params,
        returns = returns,
        func = function(...) return ... end,
      }
    end

    it('should accept a wrapped (Animal) -> Cat where '
      .. '(Cat) -> Animal is expected', function()
      local wrapped = make_wrapped({Animal}, {Cat})
      local C = Callable({Cat}, {Animal})
      expect(C:__isinstance(wrapped)).to.be_true()
      expect(isinstance(wrapped, C)).to.be_true()
    end)

    it('should reject a wrapped (Cat) -> Animal where '
      .. '(Animal) -> Cat is expected', function()
      local wrapped = make_wrapped({Cat}, {Animal})
      local C = Callable({Animal}, {Cat})
      expect(C:__isinstance(wrapped)).to.be_false()
    end)

    it('should accept a wrapped function returning a '
      .. 'narrower number type', function()
      local wrapped = make_wrapped({Number}, {Integer})
      local C = Callable({Integer}, {Number})
      expect(C:__isinstance(wrapped)).to.be_true()
    end)

    it('should match a wrapped variadic function against a fixed '
      .. 'Callable covering its prefix', function()
      local wrapped = make_wrapped({String, VARARG}, {})
      expect(isinstance(wrapped, Callable({String, Integer}, {})))
        .to.be_true()
      expect(isinstance(wrapped, Callable({Integer, Integer}, {})))
        .to.be_false()
    end)

    it('should match a wrapped variadic function against a '
      .. 'variadic Callable', function()
      local wrapped = make_wrapped({String, VARARG}, {})
      expect(isinstance(wrapped, Callable({String, VARARG}, {})))
        .to.be_true()
      expect(isinstance(wrapped, Callable({VARARG}, {})))
        .to.be_false()
    end)

    it('should reject a wrapped fixed function against a '
      .. 'variadic Callable', function()
      local wrapped = make_wrapped({String}, {})
      expect(isinstance(wrapped, Callable({String, VARARG}, {})))
        .to.be_false()
    end)
  end)

  describe('TypeVar exclusion', function()
    -- Type variables are excluded from the variance relation in this
    -- first iteration: a TypeVar relates only to itself (and to Any,
    -- as every type does). See llx.types.matchers.TypeVar.
    local TypeVar = matchers.TypeVar

    it('should be reflexive for a TypeVar', function()
      local T = TypeVar('T')
      expect(is_subtype(T, T)).to.be_true()
    end)

    it('should not conflate distinct TypeVars sharing a name',
        function()
      local T1 = TypeVar('T')
      local T2 = TypeVar('T')
      expect(is_subtype(T1, T2)).to.be_false()
      expect(is_subtype(T2, T1)).to.be_false()
    end)

    it('should widen a TypeVar to Any but never the reverse',
        function()
      local T = TypeVar('T')
      expect(is_subtype(T, Any)).to.be_true()
      expect(is_subtype(Any, T)).to.be_false()
    end)

    it('should not relate a TypeVar to concrete types', function()
      local T = TypeVar('T')
      expect(is_subtype(T, Integer)).to.be_false()
      expect(is_subtype(Integer, T)).to.be_false()
      expect(is_subtype('T', T)).to.be_false()
      expect(is_subtype(T, 'T')).to.be_false()
    end)

    it('should not relate a TypeVar to its bound', function()
      local N = TypeVar('N', {bound = Number})
      expect(is_subtype(N, Number)).to.be_false()
      expect(is_subtype(Number, N)).to.be_false()
    end)

    it('should accept generic signatures only through TypeVar '
      .. 'identity', function()
      local T = TypeVar('T')
      local U = TypeVar('U')
      local generic = {params = {T}, returns = {T}}
      expect(signature_compatible(generic, generic)).to.be_true()
      expect(signature_compatible(
          {params = {T}, returns = {T}},
          {params = {U}, returns = {U}})).to.be_false()
    end)

    it('should conservatively reject a generic signature against '
      .. 'a concrete Callable', function()
      local T = TypeVar('T')
      local wrapped = signature.Function{
        params = {T},
        returns = {T},
        func = function(x) return x end,
      }
      expect(isinstance(wrapped, Callable({Integer}, {Integer})))
        .to.be_false()
      -- Only the return position may widen (covariantly) to Any.
      expect(isinstance(wrapped, Callable({T}, {Any})))
        .to.be_true()
    end)
  end)
end)

describe('generator_compatible', function()
  describe('reflexivity and defaults', function()
    it('should accept identical contracts', function()
      local contract = {yields = {Integer}, accepts = {String},
                        returns = {Number}}
      expect(generator_compatible(contract, contract)).to.be_true()
    end)

    it('should default missing lists to empty', function()
      expect(generator_compatible({}, {})).to.be_true()
      expect(generator_compatible({yields = {}}, {})).to.be_true()
      expect(generator_compatible({}, {yields = {Integer}}))
        .to.be_false()
    end)

    it('should reject non-table operands', function()
      expect(generator_compatible(nil, {})).to.be_false()
      expect(generator_compatible({}, 42)).to.be_false()
    end)
  end)

  describe('variance', function()
    it('should treat yields covariantly', function()
      expect(generator_compatible({yields = {Integer}},
                                  {yields = {Number}})).to.be_true()
      expect(generator_compatible({yields = {Number}},
                                  {yields = {Integer}})).to.be_false()
    end)

    it('should treat accepts contravariantly', function()
      expect(generator_compatible({accepts = {Number}},
                                  {accepts = {Integer}})).to.be_true()
      expect(generator_compatible({accepts = {Integer}},
                                  {accepts = {Number}})).to.be_false()
    end)

    it('should treat returns covariantly', function()
      expect(generator_compatible({returns = {Integer}},
                                  {returns = {Number}})).to.be_true()
      expect(generator_compatible({returns = {Number}},
                                  {returns = {Integer}})).to.be_false()
    end)

    it('should require every list to be compatible', function()
      local sub = {yields = {Integer}, accepts = {Number},
                   returns = {Integer}}
      expect(generator_compatible(sub, {yields = {Number},
                                        accepts = {Integer},
                                        returns = {Number}}))
        .to.be_true()
      expect(generator_compatible(sub, {yields = {Number},
                                        accepts = {Integer},
                                        returns = {String}}))
        .to.be_false()
    end)
  end)

  describe('arity and variadic tails', function()
    it('should require exact arity on fixed lists', function()
      expect(generator_compatible({yields = {Integer, Integer}},
                                  {yields = {Integer}})).to.be_false()
      expect(generator_compatible({accepts = {Integer}},
                                  {accepts = {Integer, Integer}}))
        .to.be_false()
    end)

    it('should apply return-list variadic rules to yields', function()
      expect(generator_compatible({yields = {Integer, Integer}},
                                  {yields = {Integer, VARARG}}))
        .to.be_true()
      expect(generator_compatible({yields = {Integer, VARARG}},
                                  {yields = {Integer}})).to.be_false()
    end)

    it('should apply parameter-list variadic rules to '
      .. 'accepts', function()
      expect(generator_compatible({accepts = {Integer, VARARG}},
                                  {accepts = {Integer, Number}}))
        .to.be_true()
      expect(generator_compatible({accepts = {Integer}},
                                  {accepts = {Integer, VARARG}}))
        .to.be_false()
    end)

    it('should reject a malformed non-trailing VARARG', function()
      expect(generator_compatible({yields = {VARARG, Integer}},
                                  {yields = {VARARG, Integer}}))
        .to.be_false()
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
