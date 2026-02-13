-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local List = require 'llx.types.list' . List
local Table = require 'llx.types.table' . Table

local _ENV, _M = environment.create_module_environment()

Set = class 'Set' {
  __init = function(self, values)
    local _values = {}
    rawset(self, '_values', _values)
    for i=1, values and #values or 0 do
      local key = values[i]
      _values[key] = true
    end
  end,

  copy = function(self)
    local result = Set()
    rawset(result, '_values', Table.copy(rawget(self, '_values')))
    return result
  end,

  __eq = function(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
      return false
    end

    local a_values = rawget(a, '_values')
    local b_values = rawget(b, '_values')

    -- Check if all elements in set A are also in set B
    for k, v in pairs(a_values) do
      if not b_values[k] then
        return false
      end
    end

    -- Check if all elements in set B are also in set A
    for k, v in pairs(b_values) do
      if not a_values[k] then
        return false
      end
    end

    return true
  end,

  insert = function(self, key)
    rawget(self, '_values')[key] = true
  end,

  remove = function(self, key)
    rawget(self, '_values')[key] = nil
  end,

  union = function(self, other)
    local result = self:copy()
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k, v in pairs(other_values) do
      result_values[k] = true
    end
    return result
  end,

  difference = function(self, other)
    local result = Set{}
    local self_values = rawget(self, '_values')
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k, v in pairs(self_values) do
      if not other_values[k] then
        result_values[k] = true
      end
    end
    return result
  end,

  intersection = function(self, other)
    local result = Set{}
    local self_values = rawget(self, '_values')
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k, v in pairs(self_values) do
      if other_values[k] then
        result_values[k] = true
      end
    end
    return result
  end,

  symmetric_difference = function(self, other)
    local result = Set{}
    local self_values = rawget(self, '_values')
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k in pairs(self_values) do
      if not other_values[k] then
        result_values[k] = true
      end
    end
    for k in pairs(other_values) do
      if not self_values[k] then
        result_values[k] = true
      end
    end
    return result
  end,

  is_subset = function(self, other)
    local self_values = rawget(self, '_values')
    local other_values = rawget(other, '_values')
    for k in pairs(self_values) do
      if not other_values[k] then
        return false
      end
    end
    return true
  end,

  is_superset = function(self, other)
    return other:is_subset(self)
  end,

  is_disjoint = function(self, other)
    local self_values = rawget(self, '_values')
    local other_values = rawget(other, '_values')
    for k in pairs(self_values) do
      if other_values[k] then
        return false
      end
    end
    return true
  end,

  len = function(self)
    local n = 0
    for _ in pairs(rawget(self, '_values')) do
      n = n + 1
    end
    return n
  end,

  __len = function(self)
    local n = 0
    for _ in pairs(rawget(self, '_values')) do
      n = n + 1
    end
    return n
  end,

  contains = function(self, key)
    return rawget(self, '_values')[key] == true
  end,

  get = function(self, key)
    return rawget(self, '_values')[key]
  end,

  set = function(self, key, value)
    rawget(self, '_values')[key] = value and true or nil
  end,

  update = function(self, other)
    local self_values = rawget(self, '_values')
    for k in pairs(rawget(other, '_values')) do
      self_values[k] = true
    end
  end,

  clear = function(self)
    rawset(self, '_values', {})
  end,

  map = function(self, f)
    local result = Set{}
    local result_values = rawget(result, '_values')
    for k in pairs(rawget(self, '_values')) do
      result_values[f(k)] = true
    end
    return result
  end,

  filter = function(self, pred)
    local result = Set{}
    local result_values = rawget(result, '_values')
    for k in pairs(rawget(self, '_values')) do
      if pred(k) then
        result_values[k] = true
      end
    end
    return result
  end,

  tolist = function(self)
    local result = List{}
    for k, v in pairs(rawget(self, '_values')) do
      result:insert(k)
    end
    return result
  end,

  __index = function(self, key)
    local method = Set[key]
    if method ~= nil then
      return method
    end
    return rawget(self, '_values')[key]
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    local sum = 0
    for k in pairs(rawget(self, '_values')) do
      sum = (sum + hash.hash(k)) & 0xFFFFFFFF
    end
    return hash.hash_integer(sum, result)
  end,

  __tostring = function(self)
    local values = {}
    for k, v in pairs(rawget(self, '_values')) do
      table.insert(values, tostring(k))
    end
    table.sort(values)
    return "Set{" .. table.concat(values, ', ') .. "}"
  end,

  __pairs = function(self)
    return pairs(rawget(self, '_values'))
  end,
}

Set.__bor = Set.union
Set.__sub = Set.difference
Set.__band = Set.intersection
Set.__bxor = Set.symmetric_difference
Set.__newindex = Set.set

return _M
