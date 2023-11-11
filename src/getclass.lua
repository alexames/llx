require 'llx/src/types'

function getclass(value)
  local type = type(value)
  if type == 'nil' then
    return Nil
  elseif type == 'boolean' then
    return Boolean
  elseif type == 'number' then
    return Number
  elseif type == 'string' then
    return String
  elseif type == 'table' then
    return getmetatable(value) or Table
  elseif type == 'function' then
    return Function
  elseif type == 'thread' then
    return Thread
  elseif type == 'userdata' then
    return getmetatable(value) or Userdata
  end
end