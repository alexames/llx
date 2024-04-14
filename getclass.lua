-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'
local types = require 'llx/types'

local _ENV, _M = environment.create_module_environment()

function getclass(value)
  local type = type(value)
  if type == 'nil' then
    return types.Nil
  elseif type == 'boolean' then
    return types.Boolean
  elseif type == 'number' then
    return types.Number
  elseif type == 'string' then
    return types.String
  elseif type == 'table' then
    return getmetatable(value) or types.Table
  elseif type == 'function' then
    return types.Function
  elseif type == 'thread' then
    return types.Thread
  elseif type == 'userdata' then
    return getmetatable(value) or types.Userdata
  end
end

return _M
