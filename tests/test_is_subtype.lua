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
local Union = matchers.Union
local Optional = matchers.Optional
local Dict = matchers.Dict
local Callable = matchers.Callable

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
