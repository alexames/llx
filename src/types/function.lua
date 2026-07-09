-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local isinstance_module = require 'llx.isinstance'

local _ENV, _M = environment.create_module_environment()

local isinstance = isinstance_module.isinstance

Function = {}

Function.__name = 'function';

-- Required lazily inside __isinstance: llx.signature depends
-- (indirectly) on llx.types, so a top-level require here would create
-- a load-time cycle. Cached in an upvalue after the first use.
local signature_module = nil

function Function:__isinstance(value)
  if type(value) == 'function' then
    return true
  end
  -- Signature-wrapped functions (llx.signature Function instances)
  -- and overload sets (llx.signature Overload instances) are callable
  -- tables that carry declared signatures; they are accepted so that
  -- annotating a function with Signature or Overload does not make it
  -- fail type checks it previously passed. Arbitrary tables with a
  -- __call metamethod are still rejected.
  if type(value) ~= 'table' then
    return false
  end
  signature_module = signature_module or require 'llx.signature'
  return isinstance(value, signature_module.Function)
      or isinstance(value, signature_module.Overload)
end

local metatable = {}

function metatable:__tostring()
  return 'Function'
end

setmetatable(Function, metatable)

return _M
