-- Tests for generic class parameters: the `: generic(...)` class
-- declaration, `__type_params` reflection, subscription
-- (Pool[Integer] / Cache[{String, Integer}]), the GenericAlias
-- matcher with its arity / bound validation, get_origin / get_args,
-- value-level erasure, the is_subtype variance rules, and repr /
-- parse round-tripping through the subscription spelling.

local unit = require 'llx.unit'
local llx = require 'llx'
local matchers = require 'llx.types.matchers'

local is_subtype = require 'llx.is_subtype' . is_subtype

local class = llx.class
local isinstance = llx.isinstance
local Boolean = llx.Boolean
local Integer = llx.Integer
local Number = llx.Number
local String = llx.String
local Dynamic = matchers.Dynamic
local GenericAlias = matchers.GenericAlias
local get_origin = matchers.get_origin
local get_args = matchers.get_args

local Pool = class 'Pool' : generic('T') {}
local Cache = class 'Cache'
  : generic({name = 'K'}, {name = 'V', variance = 'covariant'}) {}
local Sink = class 'Sink'
  : generic({name = 'T', variance = 'contravariant'}) {}
local NumBox = class 'NumBox' : generic({name = 'T', bound = Number}) {}
local Plain = class 'Plain' {}
local SubPool = class 'SubPool' : extends(Pool) {}

_ENV = unit.create_test_env(_ENV)

describe('generic class declaration', function()
  it('records __type_params with defaults for reflection', function()
    local params = Pool.__type_params
    expect(#params).to.be_equal_to(1)
    expect(params[1].name).to.be_equal_to('T')
    expect(params[1].variance).to.be_equal_to('invariant')
    expect(params[1].bound).to.be_nil()
  end)

  it('records explicit variance and bounds', function()
    expect(Cache.__type_params[2].variance).to.be_equal_to('covariant')
    expect(Sink.__type_params[1].variance)
      .to.be_equal_to('contravariant')
    expect(NumBox.__type_params[1].bound).to.be_equal_to(Number)
  end)

  it('rejects malformed declarations', function()
    expect(function() class 'G1' : generic() {} end).to.throw()
    expect(function() class 'G2' : generic('T', 'T') {} end).to.throw()
    expect(function()
      class 'G3' : generic({name = 'T', variance = 'sideways'}) {}
    end).to.throw()
    expect(function() class 'G4' : generic(42) {} end).to.throw()
  end)

  it('leaves non-generic classes without params', function()
    expect(Plain.__type_params).to.be_nil()
  end)
end)

describe('subscription and GenericAlias construction', function()
  it('subscribes a single parameter', function()
    local alias = Pool[Integer]
    expect(get_origin(alias) == Pool).to.be_true()
    local args = get_args(alias)
    expect(#args).to.be_equal_to(1)
    expect(args[1]).to.be_equal_to(Integer)
    expect(tostring(alias)).to.be_equal_to('Pool[Integer]')
  end)

  it('subscribes several parameters via a list', function()
    local alias = Cache[{String, Integer}]
    local args = get_args(alias)
    expect(#args).to.be_equal_to(2)
    expect(args[1]).to.be_equal_to(String)
    expect(args[2]).to.be_equal_to(Integer)
  end)

  it('matches the canonical constructor', function()
    local sugar = Pool[Integer]
    local canonical = GenericAlias(Pool, {Integer})
    expect(is_subtype(sugar, canonical)).to.be_true()
    expect(is_subtype(canonical, sugar)).to.be_true()
  end)

  it('validates arity', function()
    expect(function() return GenericAlias(Pool, {Integer, Integer}) end)
      .to.throw()
    expect(function() return Cache[Integer] end).to.throw()
  end)

  it('validates bounds (Dynamic satisfies any bound)', function()
    expect(function() return NumBox[String] end).to.throw()
    local ok = NumBox[Integer]
    expect(get_args(ok)[1]).to.be_equal_to(Integer)
    expect(get_args(NumBox[Dynamic])[1]).to.be_equal_to(Dynamic)
  end)

  it('rejects subscription on a class without type parameters',
      function()
    expect(function() return GenericAlias(Plain, {Integer}) end)
      .to.throw()
    -- Non-generic classes keep plain field-lookup behavior for
    -- non-string keys: no alias, no error, just nil.
    expect(Plain[Integer]).to.be_nil()
  end)

  it('does not intercept instance indexing', function()
    local p = Pool()
    expect(p[Integer]).to.be_nil()
  end)

  it('leaves non-type keys as plain field lookups', function()
    -- ipairs probes t[1] through __index and must terminate cleanly;
    -- numeric / boolean / function keys are not subscriptions.
    expect(Pool[1]).to.be_nil()
    expect(Pool[true]).to.be_nil()
    expect(Pool[print]).to.be_nil()
    for _ in ipairs(Pool) do error('ipairs over a class yielded') end
    -- A non-type table key is a field lookup too, not a junk alias.
    expect(Pool[{1, 'not a type'}]).to.be_nil()
    expect(Pool[{}]).to.be_nil()
  end)

  it('keeps inherited-field walks free of subscriptions', function()
    -- A SubPool instance's missing-key lookup walks Pool's proxy; the
    -- walk must never mint aliases, whatever the key shape.
    local sp = SubPool()
    expect(sp[1]).to.be_nil()
    expect(sp[Integer]).to.be_nil()
    for _ in ipairs(sp) do error('ipairs over an instance yielded') end
  end)

  it('subscribes subclasses with the SUBCLASS as origin', function()
    -- __type_params inherit (as Python subclasses inherit
    -- __class_getitem__), and the alias reflects the class actually
    -- subscribed -- agreeing with the canonical constructor.
    local alias = SubPool[Integer]
    expect(get_origin(alias) == SubPool).to.be_true()
    expect(SubPool.__type_params[1].name).to.be_equal_to('T')
    expect(alias == GenericAlias(SubPool, {Integer})).to.be_true()
    -- Erasure follows the origin's class chain.
    expect(is_subtype(alias, SubPool)).to.be_true()
    expect(is_subtype(alias, Pool)).to.be_true()
    -- Cross-origin aliases stay unrelated (inheritance-mapped
    -- arguments are deferred; refusing is the sound verdict).
    expect(is_subtype(alias, Pool[Integer])).to.be_false()
    expect(is_subtype(Pool[Integer], alias)).to.be_false()
  end)

  it('rejects non-type arguments with a targeted error', function()
    local ok, err = pcall(function()
      return GenericAlias(Pool, {42})
    end)
    expect(ok).to.be_false()
    expect(tostring(err):find('is not a type', 1, true))
      .to_not.be_nil()
  end)

  it('compares aliases structurally with ==', function()
    expect(Pool[Integer] == Pool[Integer]).to.be_true()
    expect(Pool[Integer] == Pool[String]).to.be_false()
    expect(Pool[Integer] == SubPool[Integer]).to.be_false()
    expect(Cache[{String, Integer}] == Cache[{String, Integer}])
      .to.be_true()
  end)

  it('reflection probes return nil for non-aliases', function()
    expect(get_origin(Integer)).to.be_nil()
    expect(get_args(Pool)).to.be_nil()
  end)
end)

describe('value-level semantics (runtime erasure)', function()
  it('isinstance checks the origin only, like Python', function()
    local p = Pool()
    expect(isinstance(p, Pool[Integer])).to.be_true()
    expect(isinstance(p, Pool[String])).to.be_true()
    expect(isinstance(42, Pool[Integer])).to.be_false()
    expect(isinstance(Plain(), Pool[Integer])).to.be_false()
  end)
end)

describe('is_subtype over aliases', function()
  it('invariant parameters require mutual subtypes', function()
    expect(is_subtype(Pool[Integer], Pool[Integer])).to.be_true()
    expect(is_subtype(Pool[Integer], Pool[Number])).to.be_false()
    expect(is_subtype(Pool[Number], Pool[Integer])).to.be_false()
  end)

  it('covariant parameters widen one way', function()
    local a = Cache[{String, Integer}]
    local b = Cache[{String, Number}]
    expect(is_subtype(a, b)).to.be_true()
    expect(is_subtype(b, a)).to.be_false()
  end)

  it('invariant parameters stay exact beside covariant ones', function()
    -- Cache's K is invariant: widening the key rejects even though
    -- the value position is covariant.
    local a = Cache[{Integer, Integer}]
    local b = Cache[{Number, Integer}]
    expect(is_subtype(a, b)).to.be_false()
    expect(is_subtype(b, a)).to.be_false()
  end)

  it('contravariant parameters narrow the other way', function()
    expect(is_subtype(Sink[Number], Sink[Integer])).to.be_true()
    expect(is_subtype(Sink[Integer], Sink[Number])).to.be_false()
  end)

  it('Dynamic arguments defer in both directions', function()
    expect(is_subtype(Pool[Dynamic], Pool[Integer])).to.be_true()
    expect(is_subtype(Pool[Integer], Pool[Dynamic])).to.be_true()
  end)

  it('different origins are unrelated even with equal arguments',
      function()
    expect(is_subtype(Pool[Integer], Cache[{Integer, Integer}]))
      .to.be_false()
  end)

  it('erases against a bare class, gradually the other way', function()
    expect(is_subtype(Pool[Integer], Pool)).to.be_true()
    expect(is_subtype(Pool, Pool[Integer])).to.be_true()
    expect(is_subtype(SubPool, Pool[Integer])).to.be_true()
    expect(is_subtype(Pool[Integer], Plain)).to.be_false()
    expect(is_subtype(Plain, Pool[Integer])).to.be_false()
  end)

  it('participates in the standard rules unchanged', function()
    expect(is_subtype(Pool[Integer], matchers.Any)).to.be_true()
    expect(is_subtype(Dynamic, Pool[Integer])).to.be_true()
    expect(is_subtype(Pool[Integer],
                      matchers.Union{Pool[Integer], String})).to.be_true()
    expect(is_subtype(Pool[Integer], Integer)).to.be_false()
    expect(is_subtype(matchers.ListOf(Pool[Integer]),
                      matchers.ListOf(Pool[Integer]))).to.be_true()
  end)
end)

describe('generic signatures over aliases', function()
  it('unifies a TypeVar whose only occurrence is inside alias args',
      function()
    local T = matchers.TypeVar('T')
    local signature_compatible =
      require 'llx.is_subtype' . signature_compatible
    expect(signature_compatible(
      {params = {Pool[T]}, returns = {Integer}},
      {params = {Pool[Integer]}, returns = {Integer}})).to.be_true()
    -- The instantiation carries into later positions.
    expect(signature_compatible(
      {params = {Pool[T]}, returns = {T}},
      {params = {Pool[Integer]}, returns = {Integer}})).to.be_true()
    expect(signature_compatible(
      {params = {Pool[T]}, returns = {T}},
      {params = {Pool[Integer]}, returns = {String}})).to.be_false()
  end)
end)

describe('repr / parse round-trip', function()
  it('reprs to the subscription spelling and re-evaluates', function()
    expect(llx.repr(Pool[Integer])).to.be_equal_to('Pool[Integer]')
    local rt = matchers.parse('Pool[Integer]', {Pool = Pool})
    expect(get_origin(rt) == Pool).to.be_true()
    expect(get_args(rt)[1]).to.be_equal_to(Integer)
  end)

  it('round-trips several parameters through the list spelling',
      function()
    local spelled = llx.repr(Cache[{String, Integer}])
    expect(spelled).to.be_equal_to('Cache[{String, Integer}]')
    local rt = matchers.parse(spelled, {Cache = Cache})
    expect(get_origin(rt) == Cache).to.be_true()
    expect(#get_args(rt)).to.be_equal_to(2)
  end)

  it('round-trips nested inside other matchers', function()
    local nested = matchers.ListOf(Pool[Integer])
    expect(llx.repr(nested)).to.be_equal_to('ListOf(Pool[Integer])')
    local rt = matchers.parse(llx.repr(nested), {Pool = Pool})
    expect(is_subtype(rt, nested)).to.be_true()
    expect(is_subtype(nested, rt)).to.be_true()
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
