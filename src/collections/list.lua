require 'llx/src/class'
require 'llx/src/core'
require 'llx/src/types/table'

List = class 'List' : extends(Table) {}

function List.__new(t)
  return t or {}
end

function List:__eq(other)
  if #self ~= #other then
    return false
  end
  for i, v in ipairs(self) do
    if v ~= other[i] then
      return false
    end
  end
  return true
end

function List:__tostring()
  return 'List{' .. (','):join(self) .. '}'
end

function List:__index(index)
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
end

function List:extend(other)
  for i, v in ipairs(other) do
    self:insert(v)
  end
end

function List:__concat(other)
  local result = List{}
  for i=1, #self do
    result:insert(self[i])
  end
  for i=1, #other do
    result:insert(other[i])
  end
  return result
end

function List:__mul(num_copies)
  if type(self) == 'number' then
    self, num_copies = num_copies, self
  end
  local result = List{}
  for i=1, num_copies do
    result:extend(self)
  end
  return result
end

function List:contains(value)
  for i=1, #self do
    local element = self[i]
    if value == element then
      return true
    end
  end
  return false
end

function List:sub(start, finish, step)
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
end

function List:reverse()
  return self:sub(#self, 1, -1)
end

function List:__shl(n)
  if n < 0 then return self >> n
  elseif n == 0 then return self
  else return self:sub(n + 1) .. self:sub(1, n)
  end
end

function List:__shr(n)
  if n < 0 then return self << n
  elseif n == 0 then return self
  else return self:sub(-(n)) .. self:sub(1, -(n + 1))
  end
end

function List:__check_schema(schema, path, level, callback)
  local items = schema.items
  assert(items)
  local exception_list = {}
  for i=1, #self do
    local value = self[i]
    Table.insert(path, i)
    local successful, exception = callback(items, value, path, level + 1)
    if not successful then
      Table.insert(exception_list, exception)
    end
    Table.remove(path)
  end
  if #exception_list > 0 then
    return false, ExceptionGroup(exception_list, level + 1)
  end
  return true
end

List.__iterate = List.ivalues
List.__call = List.sub
List.ipairs = ipairs
List.ivalues = ivalues

return List
