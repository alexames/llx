require 'types'

local function getclass(o)
  local type = type(o)
  if type == 'nil' then
    return Nil
  elseif type == 'boolean' then
    return Boolean
  elseif type == 'number' then
    return Number
  elseif type == 'string' then
    return string
  elseif type == 'table' then
    return getmetatable(o) or Table
  elseif type == 'function' then
    return Function
  elseif type == 'thread' then
    return Thread
  elseif type == 'userdata' then
    return getmetatable(o) or Userdata
  end
end