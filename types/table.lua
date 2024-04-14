-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'
local ExceptionGroup = require 'llx/exceptions/exception_group' . ExceptionGroup
local getmetafield = require 'llx/core' . getmetafield
local SchemaMissingFieldException = require 'llx/exceptions/schema_exception' . SchemaMissingFieldException

local _ENV, _M = environment.create_module_environment()

Table = table

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
  if not v then
    v = default_func()
    self[k] = v
  end
  return v
end

function Table:get_or_insert(k, default) 
  local v = self[k]
  if not v then
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
  -- todo
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

function Table:concat(sep, i, j)
  sep = sep or ''
  i = i or 1
  j = j or #self

  local result = ''

  for k=i, j do
    local value = self[k]

    if type(value) == 'table' or type(value) == 'userdata' then
      local __tostring = getmetafield(value, '__tostring')
      if type(__tostring) ~= 'function' then
        print('>', i, __tostring)
        error('Attempt to concatenate a table or userdata without a __tostring metamethod')
      end
      value = __tostring(value)
    end

    result = result .. value

    if k < j then
      result = result .. sep
    end
  end

  return result
end

setmetatable(Table, metatable)

return _M
