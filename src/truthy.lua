-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local truthy_table = {
  ['nil']      = function(value) return false              end,
  ['boolean']  = function(value) return value              end,
  ['number']   = function(value) return value ~= 0         end,
  ['string']   = function(value) return #value > 0         end,
  ['function'] = function(value) return true               end,
  ['table']    = function(value) return next(value) ~= nil end,
  ['thread']   = function(value) return true               end,
  ['userdata'] = function(value) return true               end,
}

--- Checks if a value is truthy (not nil, false, 0, or empty).
-- @param o The value to check
-- @return true if the value is truthy, false otherwise
function truthy(o)
  return truthy_table[type(o)](o)
end

--- Checks if a value is falsey (nil, false, 0, or empty).
-- @param o The value to check
-- @return true if the value is falsey, false otherwise
function falsey(o)
  return not truthy(o)
end

return _M
