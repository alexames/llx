require 'llx/src/class'
require 'llx/src/types/list'
require 'llx/src/types/table'

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

    -- Check if the sizes of the sets are equal
    if #a_values ~= #b_values then
      return false
    end

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
    for k, v in pairs(other) do
      result_values[k] = true
    end
    return result
  end,

  difference = function(self, other)
    local result = Set{}
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k, v in pairs(self) do
      if not other_values[k] then
        result_values[k] = true
      end
    end
    return result
  end,

  intersection = function(self, other)
    local result = Set{}
    local result_values = rawget(result, '_values')
    local other_values = rawget(other, '_values')
    for k, v in pairs(self) do
      if other_values[k] then
        result_values[k] = true
      end
    end
    return result
  end,

  get = function(self, key)
    return rawget(self, '_values')[key]
  end,

  set = function(self, key, value)
    rawget(self, '_values')[key] = value and true or nil
  end,

  tolist = function(self)
    local result = List{}
    for k, v in pairs(self) do
      result:insert(k)
    end
    return result
  end,

  __index = function(self, key)
    local result = rawget(self, '_values')[key]
    if result ~= nil then
      return result
    else
      return Set[key]
    end
  end,

  __tostring = function(self)
    local values = {}
    for k, v in pairs(rawget(self, '_values')) do
      table.insert(values, tostring(k))
    end
    return "Set{" .. table.concat(values, ', ') .. "}"
  end,

  __pairs = function(self)
    return pairs(rawget(self, '_values'))
  end,
}

Set.__bor = Set.union
Set.__sub = Set.difference
Set.__band = Set.intersection
Set.__newindex = Set.set

return Set
