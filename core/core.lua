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
  local arg = {...}
  local iterator_functions, states, controls, closing_values = {}, {}, {}, {}
  for i, iterable in ipairs(arg) do
    iterator_functions[i], states[i], controls[i], closing_values[i] = each(iterable)
  end
  setmetatable(closing_values, {
    __close=function(self, err)
      -- Pass along err.
      for i=#iterator_functions, 1, -1 do
        local to_be_closed <close> = self[i]
      end
    end
  })
  local function zip_iterator_function(states, unused_control)
    local results = {}
    for i, iterator_function in ipairs(iterator_functions) do
      local iteration_results = {iterator_function(states[i], controls[i])}
      local control = iteration_results[1]
      controls[i] = control
      if control == nil then return nil end
      if #iteration_results == 1 then
        results[i] = control
      else
        results[i] = iteration_results
      end
    end
    return table.unpack(results)
  end
  return zip_iterator_function, states, controls, closing_values
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
