local function fakehash(arg)
  return arg[1]
end

local function lru(count)
  local cached_values = {}

  function cache_result(value, arg)
    -- Assume one argument for now
    for k, v in pairs(cached_values) do print(k, v) end
    cached_values[fakehash(arg)] = value
    return value
  end

  return function(underlying_function)
    return function(...)
      local arg = {...}
      -- Assume one argument for now,
      -- switch fakehash to a real hash of the arguments at some point.
      local result = cached_values[fakehash(arg)]
      if not result then
        result = cache_result({underlying_function(...)}, arg)
      end
      return unpack(result)
    end
  end
end

return {lru=lru}