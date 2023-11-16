-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

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

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function truthy(o)
  return truthy_table[type(o)](o)
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function falsey(o)
  return not truthy(o)
end

return {
  truthy=truthy,
  falsey=falsey,
}
