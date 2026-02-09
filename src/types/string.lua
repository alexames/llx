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

--- Pads a string on the left to reach a given width.
-- @param width Target width
-- @param fill Fill character (default: space)
-- @return The padded string
function String:pad_left(width, fill)
  fill = fill or ' '
  if #self >= width then return self end
  return fill:rep(width - #self) .. self
end

--- Pads a string on the right to reach a given width.
-- @param width Target width
-- @param fill Fill character (default: space)
-- @return The padded string
function String:pad_right(width, fill)
  fill = fill or ' '
  if #self >= width then return self end
  return self .. fill:rep(width - #self)
end

--- Centers a string within a given width.
-- @param width Target width
-- @param fill Fill character (default: space)
-- @return The centered string
function String:center(width, fill)
  fill = fill or ' '
  if #self >= width then return self end
  local total_pad = width - #self
  local left_pad = math.floor(total_pad / 2)
  local right_pad = total_pad - left_pad
  return fill:rep(left_pad) .. self .. fill:rep(right_pad)
end

--- Capitalizes the first character of a string.
-- @return The string with first character uppercased
function String:capitalize()
  if #self == 0 then return self end
  return self:sub(1, 1):upper() .. self:sub(2)
end

--- Splits a string into a list of words (whitespace-separated).
-- @return A List of words
function String:words()
  local List = require('llx.types.list').List
  local result = List{}
  for word in self:gmatch('%S+') do
    result[#result + 1] = word
  end
  return result
end

--- Splits a string into a list of lines.
-- @return A List of lines
function String:lines()
  local List = require('llx.types.list').List
  local result = List{}
  local pos = 1
  while true do
    local s = self:find('\n', pos, true)
    if s == nil then
      result[#result + 1] = self:sub(pos)
      break
    end
    result[#result + 1] = self:sub(pos, s - 1)
    pos = s + 1
  end
  return result
end

--- Counts non-overlapping occurrences of a plain-text substring.
-- @param sub The substring to count
-- @return The number of occurrences
function String:count(sub)
  local n = 0
  local pos = 1
  while true do
    local s, e = self:find(sub, pos, true)
    if s == nil then break end
    n = n + 1
    pos = e + 1
  end
  return n
end

--- Truncates a string to a maximum length, appending a suffix.
-- @param max_len Maximum length of the result (including suffix)
-- @param suffix Suffix to append when truncated (default: '...')
-- @return The truncated string
function String:truncate(max_len, suffix)
  if #self <= max_len then return self end
  suffix = suffix or '...'
  return self:sub(1, max_len - #suffix) .. suffix
end

--- Splits a string into words by separating on camelCase boundaries,
-- underscores, hyphens, and spaces. Returns lowercased words.
-- @return A table of lowercased word strings
local function split_words(s)
  -- Insert a separator before uppercase letters that follow lowercase or
  -- before the last letter of a consecutive uppercase run (e.g. HTMLParser -> HTML_Parser)
  local spaced = s:gsub('(%u+)(%u%l)', '%1 %2')
  spaced = spaced:gsub('(%l)(%u)', '%1 %2')
  local words = {}
  for word in spaced:gmatch('[%w]+') do
    words[#words + 1] = word:lower()
  end
  return words
end

--- Converts a string to snake_case.
-- @return The snake_cased string
function String:snake_case()
  return table.concat(split_words(self), '_')
end

--- Converts a string to camelCase.
-- @return The camelCased string
function String:camel_case()
  local words = split_words(self)
  for i = 2, #words do
    words[i] = words[i]:sub(1, 1):upper() .. words[i]:sub(2)
  end
  return table.concat(words)
end

--- Converts a string to kebab-case.
-- @return The kebab-cased string
function String:kebab_case()
  return table.concat(split_words(self), '-')
end

--- Escapes Lua pattern special characters in a string.
-- @return A string safe for use in pattern matching functions
function String:escape_pattern()
  return escape_pattern(self)
end

--- Returns true if the string is non-empty and contains only letters.
-- @return boolean
function String:is_alpha()
  return #self > 0 and self:find('^%a+$') ~= nil
end

--- Returns true if the string is non-empty and contains only digits.
-- @return boolean
function String:is_digit()
  return #self > 0 and self:find('^%d+$') ~= nil
end

--- Returns true if the string is non-empty and contains only letters and digits.
-- @return boolean
function String:is_alnum()
  return #self > 0 and self:find('^%w+$') ~= nil
end

--- Returns true if the string is non-empty and contains only whitespace.
-- @return boolean
function String:is_space()
  return #self > 0 and self:find('^%s+$') ~= nil
end

--- Substitutes ${name} placeholders with values from a table.
-- Unmatched placeholders are left unchanged.
-- @param vars Table mapping names to values
-- @return The interpolated string
function String:template(vars)
  return (self:gsub('%$%{(%w+)%}', function(key)
    local v = vars[key]
    if v ~= nil then return tostring(v) end
  end))
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
