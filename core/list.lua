require 'llx/core/class'
require 'llx/core/core'
require 'llx/core/table'

List = class 'List' : extends(Table) {}

function List.__new(t)
  return t or {}
end

function List.generate(arg)
  local lambda = arg.lambda or noop
  local iterable = arg.iterable or List.ivalues(arg.list)
  local filter = arg.filter

  local result = List{}
  while iterable do
    local v = {iterable()}
    if #v == 0 then break end
    if not filter or filter(table.unpack(v)) then
      table.insert(result, lambda(table.unpack(v)))
    end
  end
  return result
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
  if type(index) == 'number' then
    if index < 0 then
      index = #self + index + 1
    end
    return rawget(self, index)
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
  for v in self:ivalues() do
    result:insert(v)
  end
  for v in other:ivalues() do
    result:insert(v)
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

function List:slice(start, finish, step)
  start = start or 1
  finish = finish or #self
  step = step or 1

  if start < 0 then start = #self - start + 1 end
  if finish < 0 then finish = #self - finish + 1 end

  local result = List{}
  local dest = 1
  for src=start, finish, step do
    result[dest] = self[src]
    dest = dest + 1
  end
  return result
end

function List:reverse()
  return self:slice(#self, 1, -1)
end

List.__iterate = List.ivalues
List.__call = List.slice
List.ipairs = ipairs
List.ivalues = ivalues
