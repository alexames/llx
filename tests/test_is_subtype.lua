local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'
local signature = require 'llx.signature'

local is_subtype = require 'llx.is_subtype' . is_subtype
local signature_compatible =
    require 'llx.is_subtype' . signature_compatible

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
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
