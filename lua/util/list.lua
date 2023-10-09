require 'class'
require 'printValue'
require 'py'

class 'list' : extends(table)

local function noop(value)
  return value
end

function list:__init(args)
  for i, v in ipairs(args) do
    self[i] = v
  end
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
-- list.ipairs = statefulipairs
list.unpack = unpack

local function test()
  l1 = list.generate{lambda=function(n) return n * 100 end,
                     list=list{1, 2, 3, 4},
                     filter=function(n) return n % 2 == 0 end}
  print("pairs(l1)")
  for k, v in pairs(l1) do
    print("l1:", k, v)
  end
  print("1:ipairs()")
  for i, v in l1:ipairs() do
    print("l1:", i, v)
  end
  print("l1:ivalues()")
  for v in l1:ivalues() do
    print("l1:", v)
  end

  print("pairs(l2)")
  l2 = list{10, 11, 12, 13}
  for i, v in pairs(l2) do
    print("l2:", i, v)
  end
  print("list{} comprehension")
  l3 = list{iterable=range(10),
            value=function(n) return n * 100 end}
  for v in l3:ivalues() do
    print("l3:", v)
  end
end