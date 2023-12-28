-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/class'
require 'llx/src/core'
require 'llx/src/types/table'

List = class 'List' : extends(Table) {
  __new = function(t)
    return t or {}
  end,

  extend = function(self, other)
    for i, v in ipairs(other) do
      self:insert(v)
    end
  end,

  contains = function(self, value)
    for i=1, #self do
      local element = self[i]
      if value == element then
        return true
      end
    end
    return false
  end,

  sub = function(self, start, finish, step)
    local length = #self
    start = start or 1
    finish = finish or length
    step = step or 1

    if start < 0 then start = length + start + 1 end
    if start < 1 then start = 1
    elseif start > length then start = length end

    if finish < 0 then finish = length + finish + 1 end
    if finish < 0 then finish = 0
    elseif finish > length then finish = length end
    local result = List{}
    local dest = 1
    for src=start, finish, step do
      result[dest] = self[src]
      dest = dest + 1
    end
    return result
  end,

  reverse = function(self)
    return self:sub(#self, 1, -1)
  end,

  __eq = function(self, other)
    if #self ~= #other then
      return false
    end
    for i, v in ipairs(self) do
      if v ~= other[i] then
        return false
      end
    end
    return true
  end,

  __tostring = function(self)
    return 'List{' .. (', '):join(self) .. '}'
  end,

  __index = function(self, index)
    if isinstance(index, Number) then
      if index < 0 then
        index = #self + index + 1
      end
      return rawget(self, index)
    elseif isinstance(index, Table) then
      local results = List{}
      for i, v in ipairs(index) do
        results[i] = self[v]
      end
      return results
    else
      return List.__defaultindex(self, index)
    end
  end,

  __concat = function(self, other)
    local result = List{}
    for i=1, #self do
      result:insert(self[i])
    end
    for i=1, #other do
      result:insert(other[i])
    end
    return result
  end,

  __mul = function(self, num_copies)
    if type(self) == 'number' then
      self, num_copies = num_copies, self
    end
    local result = List{}
    for i=1, num_copies do
      result:extend(self)
    end
    return result
  end,

  __shl = function(self, n)
    if n < 0 then return self >> -n
    elseif n == 0 then return self
    else return self:sub(n + 1) .. self:sub(1, n)
    end
  end,

  __shr = function(self, n)
    if n < 0 then return self << -n
    elseif n == 0 then return self
    else return self:sub(-(n)) .. self:sub(1, -(n + 1))
    end
  end,

  __validate = function(self, schema, path, level, check_field)
    local items = schema.items
    local prefix_items = schema.prefix_items or {}
    if not items then return true end

    local exception_list = {}
    for i=1, #self do
      local value = self[i]
      local item_schema = prefix_items[i] or items
      if not item_schema then
        break
      end
      Table.insert(path, i)
      local successful, exception =
          check_field(item_schema, value, path, level + 1)
      if not successful then
        Table.insert(exception_list, exception)
      end
      Table.remove(path)
    end
    if #exception_list > 0 then
      return false, ExceptionGroup(exception_list, level + 1)
    end
    return true
  end,
}

List.__iterate = List.ivalues
List.__call = List.sub
List.ipairs = ipairs
List.ivalues = ivalues

return List
