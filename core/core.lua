function getmetafield(t, k)
  local metatable = debug.getmetatable(t)
  return metatable and rawget(metatable, k)
end

function printf(fmt, ...)
  print(string.format(fmt, ...))
end

function p(...)
  print(...)
  return ...
end

function each(iterable, ...)
  local __iterate = getmetafield(iterable, '__iterate')
  if __iterate then
    return __iterate(iterable)
  else
    return iterable, ...
  end
end

function range(startOrFinish, finish, step)
  local current
  if finish == nil then
    current = 1
    finish = startOrFinish
  else
    current = startOrFinish
  end
  if step == nil then
    step = 1
  end

  return function()
    local returnValue = current
    if returnValue <= finish then
      current = current + step
      return returnValue
    else
      return nil
    end
  end
end

function values(t)
  local v = nil
  return function()
    return next(t, v)
  end
end

function ivalues(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

function count(start, step)
  local i = start or 1
  step = step or 1
  return function ()
    returnValue = i
    i = i + step
    return returnValue
  end
end

function zip(...)
  local iterators = {...}
  for i = 1, #iterators do
    local iterator = iterators[i]
    assert(type(iterator) == "table",
          "you have to wrap the iterators in a table")
  end
  return function()
    local results = {}
    for i=1, #iterators do
      local iterator = iterators[i]
      local iteration_function, state, control = iterator[1], iterator[2], iterator[3]
      local iteration_results = {iteration_function(state, control)}
      control = iteration_results[1]
      if control == nil then return nil end
      iterator[3] = control
      results[i] = iteration_results
    end
    return table.unpack(results)
  end
end

function all(t)
  for i, v in ipairs(t) do
    if not v then return false end
  end
  return true
end

function any(t)
  for i, v in ipairs(t) do
    if v then return true end
  end
  return false
end

function filter(predicate, l)
  local result = {}
  for unused, value in ipairs(l) do
    if predicate(value) then
      table.insert(l, value)
    end
  end
  return result
end

function cmp(a, b)
  if a == b then return 0
  elseif a < b then return -1
  else return 1
  end
end

function max(a, b)
  return a > b and a or b
end

function max(a, b)
  return a < b and a or b
end

function collect_keys(out, ...)
  for i, t in pairs{...} do
    for k, v in pairs(t) do
      out[k] = true
    end
  end
  return out
end

function noop(...) return ... end

function printtable(t)
  for k, v in pairs(t) do print(k, v) end
end

function printlist(t)
  for i, v in ipairs(t) do print(i, v) end
end

function tointeger(value)
  local __tointeger = getmetafield(value, '__tointeger')
  return __tointeger and __tointeger(value) or math.floor(value)
end