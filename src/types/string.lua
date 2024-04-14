-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

String = string

local metatable = {}

function metatable:__call(v)
  return v and tostring(v) or ''
end;

function metatable:__tostring()
  return 'String'
end

String.__name = 'String'

function String:__isinstance(v)
  return type(v) == 'string'
end

function String:__validate(schema, path, level, check_field)
  if schema.min_length then
    if #self < schema.min_length then
      local failure_reason = string.format(
          'expected string with minimum length of %s, got string of length %s',
           schema.min_length, #self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.max_length then
    if #self > schema.max_length then
      local failure_reason = string.format(
          'expected string with maximum length of %s, got string of length %s',
           schema.max_length, #self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.pattern then
    if not self:find(schema.pattern) then
      local failure_reason = string.format(
          'expected string that matched pattern `%s`, got %s',
           schema.pattern, self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  return true
end

function String:join(t)
  local result = ''
  for i=1, #t do
    if i > 1 then
      result = result .. self
    end
    result = result .. tostring(t[i])
  end
  return result
end

function String:empty()
  return #self == 0
end

function String:startswith(start)
   return self:sub(1, #start) == start
end

function String:endswith(ending)
   return ending == "" or self:sub(-#ending) == ending
end

function String:__index(i, v)
  return self:sub(i, i)
end

local string_metatable = getmetatable('')

function string_metatable.__index(s, k)
  if type(k) == 'number' then
    return s:sub(k, k)
  else
    return string[k]
  end
end

function string_metatable.__unm(str,i)
  return string.reverse(str)
end

function string_metatable.__mul(str,i)
  return string.rep(str, i)
end

function string_metatable:__shl(n)
  if n < 0 then return self >> n end
  return self:sub(n + 1) .. self:sub(1, n)
end

function string_metatable:__shr(n)
  if n < 0 then return self << n end
  return self:sub(-(n)) .. self:sub(1, -(n + 1))
end

function string_metatable:__call(state, control)
  control = (control or 0) + 1
  if control <= #self then return control, self:sub(control, control) end
end

setmetatable(String, metatable)

return _M
