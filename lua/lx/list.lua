
local class = require 'lx/class'

local list = class 'list' : extends(table) {}

local function noop(value)
  return value
end

function list:__new(t)
  return t or {}
end

function list.generate(arg)
  local iterable = arg.iterable or list.ivalues(arg.list)
  local filter = arg.filter
  local lambdaFn = arg.lambda or noop

  local result = list{}
  while iterable do
    local v = {iterable()}
    if #v == 0 then break end
    if not filter or filter(unpack(v)) then
      table.insert(result, lambdaFn(unpack(v)))
    end
  end
  return result
end

function list:__index(index)
  if type(index) == 'number' then
    if index < 0 then
      index = #self + index + 1
    end
    return rawget(self, index)
  else
    return list.__defaultindex(self, index)
  end
end

function list:__add(other)
  result = list{}
  for v in self:ivalues() do
    result:insert(v)
  end
  for v in other:ivalues() do
    result:insert(v)
  end
  return result
end

function list:ivalues()
  local i = 0
  return function()
    i = i + 1
    return self[i]
  end
end

function list:contains(value)
  for element in self:ivalues() do
    if value == element then
      return true
    end
  end
  return false
end

function list:slice(start, finish, step)
  start = start or 1
  finish = finish or #self
  step = step or 1

  if start < 0 then start = #self - start + 1 end
  if finish < 0 then finish = #self - finish + 1 end

  result = list{}
  local dest = 1
  for src=start, finish, step do
    result[dest] = self[src]
    dest = dest + 1
  end
  return result
end

function list:reverse()
  return list:slice(nil, nil, -1)
end

list.__call = list.slice
list.ipairs = ipairs

return list
