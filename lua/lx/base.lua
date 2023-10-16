
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
  local i = 0
  return function()
    i = i + 1
    local tuple = {}
    for index, list in ipairs(arg) do
      local element = list[i]
      if element == nil then return nil end
      tuple[index] = element
    end
    return unpack(tuple)
  end
end

function zipLongest(...)
  local result = {}
  for i in count() do
    local tuple = {}
    local foundElement = false
    for index, list in ipairs(arg) do
      local element = list[i]
      foundElement = foundElement or (element ~= nil)
      tuple[index] = element
    end
    if foundElement then
      table.insert(result, tuple)
    else
      return result
    end
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