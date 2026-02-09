-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local ExceptionGroup = require 'llx.exceptions.exception_group' . ExceptionGroup
local getmetafield = require 'llx.core' . getmetafield
local SchemaMissingFieldException = require 'llx.exceptions.schema_exception' . SchemaMissingFieldException

local _ENV, _M = environment.create_module_environment()

Table = table

-- Save a reference to the original table.concat before it is overridden below.
local builtin_concat = table.concat

Table.__name = 'Table';

function Table:__isinstance(v)
  return type(v) == 'table'
end

local function contains(list, value)
  for i=1, #list do
    local element = list[i]
    if value == element then
      return true
    end
  end
  return false
end

function Table:__validate(schema, path, level, check_field)
  local properties = schema.properties
  local required = schema.required
  local exception_list = {}
  if properties then
    for key, property in pairs(properties) do
      local value = self[key]
      if value == nil then
        if required and contains(required, key) then
          Table.insert(exception_list,
                       SchemaMissingFieldException(path, key, level + 1))
        end
      else
        Table.insert(path, key)
        local successful, exception =
            check_field(property, value, path, level + 1)
        if not successful then
          Table.insert(exception_list, exception)
        end
        Table.remove(path)
      end
    end
    if #exception_list > 0 then
      return false, ExceptionGroup(exception_list, level + 1)
    end
  end
  return true
end

local table_instance_metatable = {
  __index = Table,

  __call = function(self, state, control)
    control = next(self, control)
    local value = self[control]
    return value and control, value
  end,
}

local metatable = {}

function metatable:__call(tbl)
  return setmetatable(tbl or {}, table_instance_metatable)
end

function metatable.__tostring()
  return 'Table'
end

function Table:remove_if(predicate)
  local j = 1
  local size = #self
  for i=1, size do
    if not predicate(self[i]) then
      if (i ~= j) then
        self[j] = self[i]
        self[i] = nil
      end
      j = j + 1
    else
      self[i] = nil
    end
  end
  return self
end

function Table:get_or_insert_lazy(k, default_func)
  local v = self[k]
  if v == nil then
    v = default_func()
    self[k] = v
  end
  return v
end

function Table:get_or_insert(k, default)
  local v = self[k]
  if v == nil then
    v = default
    self[k] = v
  end
  return v
end

function Table:copy(destination)
  local destination = destination or {}
  for k, v in pairs(self) do
    destination[k] = v
  end
  return destination
end

function Table:deepcopy(destination)
  destination = destination or {}
  local visited = {}

  local function deepcopy_helper(src, dst)
    if type(src) ~= 'table' then
      return src
    end

    -- Handle circular references
    if visited[src] then
      return visited[src]
    end

    visited[src] = dst

    -- Preserve metatable so typed objects retain their type after deep copy.
    local mt = getmetatable(src)
    if mt then
      setmetatable(dst, mt)
    end

    for k, v in pairs(src) do
      if type(v) == 'table' then
        if visited[v] then
          dst[k] = visited[v]
        else
          dst[k] = {}
          deepcopy_helper(v, dst[k])
        end
      else
        dst[k] = v
      end
    end

    return dst
  end

  return deepcopy_helper(self, destination)
end

function Table:apply(xform)
  for k, v in pairs(self) do
    self[k] = xform(v)
  end
end

function Table:find(value)
  for k, v in pairs(self) do
    if v == value then
      return k, v
    end
  end
end

function Table:find_if(predicate)
  for k, v in pairs(self) do
    if predicate(k, v) then
      return k, v
    end
  end
end

function Table:ifind(value, init)
  for i=init or 1, #self do
    if self[i] == value then
      return i, value
    end
  end
end

function Table:ifind_if(predicate, init)
  for i=init or 1, #self do
    if predicate(i, self[i]) then
      return i, self[i]
    end
  end
end

function Table:insert_unique(value)
  if not self:ifind(value) then
    self:insert(value)
  end
end

--- Returns a List of all keys in the table.
-- @return List of keys
-- @usage Table.keys({a=1, b=2})  -- returns List{'a', 'b'}
function Table:keys()
  local List = require('llx.types.list').List
  local result = List{}
  for k in pairs(self) do
    result[#result + 1] = k
  end
  return result
end

--- Returns a List of {key, value} pairs.
-- @return List of Lists, each containing {key, value}
-- @usage Table.entries({a=1})  -- returns List{List{'a', 1}}
function Table:entries()
  local List = require('llx.types.list').List
  local result = List{}
  for k, v in pairs(self) do
    result[#result + 1] = List{k, v}
  end
  return result
end

--- Constructs a table from a list of {key, value} pairs.
-- Inverse of entries.
-- @param pairs_list A list of {key, value} tables
-- @return A new table
-- @usage Table.from_entries({{'a', 1}, {'b', 2}})  -- returns {a=1, b=2}
function Table.from_entries(pairs_list)
  local result = {}
  for i = 1, #pairs_list do
    local pair = pairs_list[i]
    result[pair[1]] = pair[2]
  end
  return result
end

--- Shallow-merges multiple tables into a new table.
-- Later tables overwrite earlier ones for duplicate keys.
-- Does not modify any input table.
-- @param ... Tables to merge
-- @return A new merged table
-- @usage Table.merge({a=1}, {b=2}, {a=3})  -- returns {a=3, b=2}
function Table.merge(...)
  local result = {}
  for i = 1, select('#', ...) do
    local t = select(i, ...)
    for k, v in pairs(t) do
      result[k] = v
    end
  end
  return result
end

--- Returns a new table containing only the specified keys.
-- @param keys_list A list of keys to include
-- @return A new table with only those keys
-- @usage Table.pick({a=1, b=2, c=3}, {'a', 'c'})  -- returns {a=1, c=3}
function Table:pick(keys_list)
  local result = {}
  for i = 1, #keys_list do
    local k = keys_list[i]
    if self[k] ~= nil then
      result[k] = self[k]
    end
  end
  return result
end

--- Returns a new table excluding the specified keys.
-- @param keys_list A list of keys to exclude
-- @return A new table without those keys
-- @usage Table.omit({a=1, b=2, c=3}, {'b'})  -- returns {a=1, c=3}
function Table:omit(keys_list)
  local exclude = {}
  for i = 1, #keys_list do
    exclude[keys_list[i]] = true
  end
  local result = {}
  for k, v in pairs(self) do
    if not exclude[k] then
      result[k] = v
    end
  end
  return result
end

--- Swaps keys and values in a table.
-- @return A new table with keys and values swapped
-- @usage Table.invert({a='x', b='y'})  -- returns {x='a', y='b'}
function Table:invert()
  local result = {}
  for k, v in pairs(self) do
    result[v] = k
  end
  return result
end

--- Counts the total number of key-value pairs in a table.
-- Unlike #, this counts all keys (not just the array portion).
-- @return The number of key-value pairs
-- @usage Table.size({a=1, b=2})  -- returns 2
function Table:size()
  local n = 0
  for _ in pairs(self) do
    n = n + 1
  end
  return n
end

--- Checks whether a table has no keys.
-- @return true if the table is empty, false otherwise
-- @usage Table.is_empty({})  -- returns true
function Table:is_empty()
  return next(self) == nil
end

function Table:concat(sep, i, j)
  sep = sep or ''
  i = i or 1
  j = j or #self

  local parts = {}

  for k=i, j do
    local value = self[k]

    if type(value) == 'table' or type(value) == 'userdata' then
      local __tostring = getmetafield(value, '__tostring')
      if type(__tostring) ~= 'function' then
        error('Attempt to concatenate a table or userdata without a __tostring metamethod')
      end
      value = __tostring(value)
    end

    parts[#parts + 1] = value
  end

  return builtin_concat(parts, sep)
end

setmetatable(Table, metatable)

return _M
