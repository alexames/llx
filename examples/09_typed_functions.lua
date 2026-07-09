-- examples/09_typed_functions.lua
-- Typed functions: Signature declarations with runtime enforcement,
-- the Callable matcher, and the subtype / variance relations.

local llx = require 'llx'
local matchers = require 'llx.types.matchers'
local signature_module = require 'llx.signature'

local class = llx.class
local isinstance = llx.isinstance
local is_subtype = llx.is_subtype
local signature_compatible = llx.signature_compatible

local Integer = llx.Integer
local Number = llx.Number
local String = llx.String
local Any = llx.Any
local Optional = llx.Optional
local Union = llx.Union
local Callable = matchers.Callable
local Signature = signature_module.Signature

-- ---------------------------------------------------------------------
-- 1. Signature: declare argument and return types on a method.
--
-- The `'name' | Signature{...}` decorator wraps the method in a typed
-- Function object. Every call checks the arguments against `params`
-- and the results against `returns`. Note that methods receive self,
-- so the receiving class is declared first (by name, as a string).
-- ---------------------------------------------------------------------

local Greeter = class 'Greeter' {
  ['greet' | Signature{params={'Greeter', String, Integer},
                        returns={String}}] =
  function(self, name, times)
    return string.rep('hi ' .. name .. '! ', times)
  end,
}

local greeter = Greeter()
print(greeter:greet('ada', 2))       --> hi ada! hi ada!

-- A wrong argument type raises before the function body runs.
local ok, err = pcall(function() greeter:greet('ada', 'twice') end)
print(ok, err:message())
--> false InvalidArgumentTypeException: bad argument #3:
-->   Integer expected, got String

-- Arity is enforced: extra, undeclared arguments raise too.
ok, err = pcall(function() greeter:greet('ada', 2, 'surprise') end)
print(ok, err:message())
--> false InvalidArgumentException: bad argument #4:
-->   expected at most 3 value(s), got 4

-- Return values are checked the same way, including their count.
local Sneaky = class 'Sneaky' {
  ['pair' | Signature{params={'Sneaky'}, returns={Integer}}] =
  function(self)
    return 1, 'extra'                -- declared one return, gives two
  end,
}
ok, err = pcall(function() Sneaky():pair() end)
print(ok, err:message())
--> false InvalidArgumentException: bad argument #2:
-->   expected at most 1 value(s), got 2

-- A trailing '...' makes a signature variadic: the fixed prefix is
-- still type-checked, and anything beyond it is allowed unchecked.
local Logger = class 'Logger' {
  ['log' | Signature{params={'Logger', String, '...'}, returns={}}] =
  function(self, fmt, ...)
    print(fmt:format(...))
  end,
}
Logger():log('%s=%d', 'answer', 42)  --> answer=42

-- Optional trailing parameters are expressed with Optional(T):
-- omitting them is fine, a wrong type is still rejected.
local Counter = class 'Counter' {
  ['step' | Signature{params={'Counter', Optional(Integer)},
                       returns={Integer}}] =
  function(self, by)
    return (by or 1)
  end,
}
print(Counter():step(), Counter():step(5))  --> 1 5

-- Free functions can be wrapped directly with decorate.
local sig = Signature{params={Number}, returns={Number}}
local _, _, halve = sig:decorate({}, 'halve', function(n) return n / 2 end)
print(halve(9))                      --> 4.5

-- ---------------------------------------------------------------------
-- 2. Callable: a *type* for functions, usable anywhere a matcher is.
--
-- Callable(params, returns) is the runtime analog of Python's
-- Callable[[A, B], R]. Signature-wrapped functions are checked
-- against their declared types; raw Lua functions carry no type
-- information, so only their arity can be checked.
-- ---------------------------------------------------------------------

local IntToString = Callable({Integer}, {String})
print(tostring(IntToString))         --> Callable<(Integer) -> (String)>

-- A wrapped function matches when its declared signature is
-- compatible with the Callable's.
local tostr_sig = Signature{params={Integer}, returns={String}}
local _, _, render = tostr_sig:decorate({}, 'render', function(n)
  return '#' .. n
end)
print(isinstance(render, IntToString))            --> true

local wrong_sig = Signature{params={String}, returns={String}}
local _, _, shout = wrong_sig:decorate({}, 'shout', function(s)
  return s:upper()
end)
print(isinstance(shout, IntToString))             --> false

-- Raw functions: lenient arity checking by default (idiomatic Lua
-- ignores extra arguments), exact arity with {strict = true}.
print(isinstance(function(n) return '' .. n end, IntToString)) --> true
print(isinstance(function(a, b) return a end, IntToString))    --> false

local StrictIntToString = Callable({Integer}, {String}, {strict=true})
print(isinstance(function() return 'x' end, IntToString))       --> true
print(isinstance(function() return 'x' end, StrictIntToString)) --> false

-- Callable composes with the other matchers, e.g. in a Protocol.
local Renderer = llx.Protocol{render = IntToString}
print(isinstance({render = render}, Renderer))    --> true

-- ---------------------------------------------------------------------
-- 3. is_subtype: can a value of type A be used where B is expected?
-- ---------------------------------------------------------------------

-- Reflexivity, the Any top type, and numeric widening.
print(is_subtype(Integer, Integer))               --> true
print(is_subtype(Integer, Any))                   --> true
print(is_subtype(Integer, Number))                --> true
print(is_subtype(Number, Integer))                --> false

-- Unions: a member is a subtype of the union; a union is a subtype
-- of B only when every member is.
print(is_subtype(Integer, Union{Integer, String}))          --> true
print(is_subtype(Union{Integer, String}, Number))           --> false
print(is_subtype(Union{Integer, llx.Float}, Number))        --> true

-- Classes: the superclass chain is walked transitively.
local Animal = class 'Animal' {}
local Dog = class 'Dog' : extends(Animal) {}
local Puppy = class 'Puppy' : extends(Dog) {}
print(is_subtype(Dog, Animal))                    --> true
print(is_subtype(Puppy, Animal))                  --> true
print(is_subtype(Animal, Dog))                    --> false

-- ---------------------------------------------------------------------
-- 4. signature_compatible: variance for function signatures.
--
-- A signature SUB may be used where SUPER is expected when
--   - parameters are CONTRAvariant: SUB must accept at least
--     everything SUPER promises to accept (each SUPER param is a
--     subtype of the matching SUB param), and
--   - returns are COvariant: SUB must produce no more than SUPER
--     promises (each SUB return is a subtype of the matching SUPER
--     return).
-- ---------------------------------------------------------------------

-- Expected: a handler that takes a Dog and returns an Animal.
local wants = {params = {Dog}, returns = {Animal}}

-- A handler taking any Animal and returning a specific Dog is fine:
-- it accepts more than required and returns something more specific.
print(signature_compatible(
  {params = {Animal}, returns = {Dog}}, wants))   --> true

-- Narrower parameter (Puppy): unsafe, the caller may pass any Dog.
print(signature_compatible(
  {params = {Puppy}, returns = {Animal}}, wants)) --> false

-- Wider return (Any): unsafe, the caller expects an Animal back.
print(signature_compatible(
  {params = {Dog}, returns = {Any}}, wants))      --> false

-- The same variance rules power Callable matching of wrapped
-- functions: a Callable expecting (Integer) -> (Number) accepts a
-- function declared (Number) -> (Integer).
local NumberFn = Callable({Integer}, {Number})
local wide_sig = Signature{params={Number}, returns={Integer}}
local _, _, double = wide_sig:decorate({}, 'double', function(n)
  return n * 2
end)
print(isinstance(double, NumberFn))               --> true

-- Arity of fixed lists must match exactly on both sides: extra
-- declared returns are observable in Lua (calls in expression-list
-- tails expand all results), so they break compatibility.
print(signature_compatible(
  {params = {Dog}, returns = {Animal, String}}, wants))      --> false

-- Variadic declarations (a trailing '...') participate soundly: a
-- variadic function can stand in for a fixed signature that covers
-- its checked prefix (the extras land in the unchecked tail), but a
-- fixed function cannot stand in for a variadic one, since callers
-- may pass extra arguments that its call-time check rejects.
local log_sig = Signature{params={String, '...'}, returns={}}
local _, _, log = log_sig:decorate({}, 'log', function(fmt, ...)
  print(fmt:format(...))
end)
print(isinstance(log, Callable({String, Integer}, {})))     --> true
print(isinstance(log, Callable({String, '...'}, {})))       --> true
print(isinstance(shout, Callable({String, '...'}, {String}))) --> false

-- Signature wrappers carry params/returns, so they can be compared
-- directly, too.
print(signature_compatible(render, tostr_sig))    --> true
