-- examples/03_schema.lua
-- Runtime type checking and schema validation.

local llx = require 'llx'

-- isinstance against built-in type checkers.
print(llx.isinstance(42, llx.Integer))       --> true
print(llx.isinstance(3.14, llx.Integer))     --> false
print(llx.isinstance('hi', llx.String))      --> true

-- Schema wraps a type so it can be used as an isinstance target
-- and given a name for clearer error messages.
local Schema = llx.Schema
local matches_schema = llx.matches_schema

local PositiveInt = Schema {
  type = llx.Integer,
  title = 'PositiveInt',
}
print(matches_schema(PositiveInt, 42))       --> true
local ok, err = matches_schema(PositiveInt, 'oops', true)
print(ok, err)                                --> false, <SchemaException>

-- Union and Optional via the matchers module.
local matchers = require 'llx.types.matchers'
local Optional = matchers.Optional
local Union = matchers.Union

local OptionalString = Optional(llx.String)
print(llx.isinstance(nil, OptionalString))    --> true
print(llx.isinstance('hello', OptionalString)) --> true
print(llx.isinstance(42, OptionalString))      --> false

local NumberOrString = Union{llx.Number, llx.String}
print(llx.isinstance(42, NumberOrString))      --> true
print(llx.isinstance('x', NumberOrString))     --> true
print(llx.isinstance(true, NumberOrString))    --> false

-- Dict for typed maps.
local Dict = matchers.Dict
local NameAges = Dict(llx.String, llx.Integer)
print(llx.isinstance({alice = 30, bob = 25}, NameAges))  --> true
print(llx.isinstance({alice = 'thirty'}, NameAges))      --> false
