require 'llx/core/class'
require 'llx/core/table'
require 'llx/core/core'

List = class 'List' : extends(Table) {}

local function noop(value)
  return value
end

function List.__new(t)
  return t or {}
end

function List.generate(arg)
  local iterable = arg.iterable or List.ivalues(arg.List)
  local filter = arg.filter
  local lambdaFn = arg.lambda or noop

  local result = List{}
  while iterable do
    local v = {iterable()}
    if #v == 0 then break end
    if not filter or filter(table.unpack(v)) then
      table.insert(result, lambdaFn(table.unpack(v)))
    end
  end
  return result
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
    table.insert(self, v)
  end
end

function List:__add(other)
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
  local result = List{}
  for i=1, num_copies do
    result:extend(self)
  end
  return result
end

function List:ivalues()
  local i = 0
  return function()
    i = i + 1
    return self[i]
  end
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

  result = List{}
  local dest = 1
  for src=start, finish, step do
    result[dest] = self[src]
    dest = dest + 1
  end
  return result
end

function List:reverse()
  return List:slice(nil, nil, -1)
end

List.__call = List.slice
List.ipairs = ipairs
