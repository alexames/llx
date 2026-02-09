-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

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

--- Escapes Lua pattern special characters in a string.
-- @param s The string to escape
-- @return A string safe for use in pattern matching functions
local function escape_pattern(s)
  return (s:gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%0'))
end

--- Splits a string by a plain-text delimiter.
-- Returns a list of substrings. When no delimiter is given, splits on
-- whitespace and discards empty parts.
-- @param delim Delimiter string (default: whitespace)
-- @return A List of substrings
-- @usage
-- ('a,b,c'):split(',')  -- returns {'a', 'b', 'c'}
-- ('hello world'):split()  -- returns {'hello', 'world'}
function String:split(delim)
  local List = require('llx.types.list').List
  if delim == nil then
    local result = List{}
    for word in self:gmatch('%S+') do
      result[#result + 1] = word
    end
    return result
  end
  local result = List{}
  local pattern = escape_pattern(delim)
  local pos = 1
  while true do
    local s, e = self:find(pattern, pos)
    if s == nil then
      result[#result + 1] = self:sub(pos)
      break
    end
    result[#result + 1] = self:sub(pos, s - 1)
    pos = e + 1
  end
  return result
end

--- Removes leading and trailing whitespace from a string.
-- @return The trimmed string
-- @usage ('  hello  '):trim()  -- returns 'hello'
function String:trim()
  return self:match('^%s*(.-)%s*$')
end

--- Removes leading whitespace from a string.
-- @return The left-trimmed string
function String:ltrim()
  return self:match('^%s*(.*)')
end

--- Removes trailing whitespace from a string.
-- @return The right-trimmed string
function String:rtrim()
  return self:match('(.-)%s*$')
end

--- Checks whether a string contains a plain-text substring.
-- @param sub The substring to search for (plain text, not a pattern)
-- @return true if the substring is found, false otherwise
-- @usage ('hello world'):contains('world')  -- returns true
function String:contains(sub)
  return self:find(sub, 1, true) ~= nil
end

--- Replaces occurrences of a plain-text substring.
-- Unlike gsub, this performs literal string replacement (no patterns).
-- @param old The substring to find (plain text)
-- @param new The replacement string
-- @param count Maximum number of replacements (default: all)
-- @return The string with replacements applied
-- @usage ('a.b.c'):replace('.', '-')  -- returns 'a-b-c'
function String:replace(old, new, count)
  local escaped = escape_pattern(old)
  local result = self:gsub(escaped, new, count)
  return result
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
