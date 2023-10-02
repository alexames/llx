--------------------------------------------------------------------------------
-- Core decorator library
local next_decorators = nil
function decorator(...)
  next_decorators = arg
end

setmetatable(_G, {
  __newindex = function(t, k, v)
    if next_decorators then
      for _, d in ipairs(next_decorators) do
        v = d(v)
      end
    end
    next_decorators = nil
    rawset(t, k, v)
  end
})

--------------------------------------------------------------------------------
-- Example decorators
function lru(count)
  local cached_values = {}
  
  function cache_result(value, arg)
    -- Assume one argument for now
    local arg1 = arg[1]
    cached_values[arg1] = value
    return value
  end

  return function(v)
    return function(...)
      -- Assume one argument for now
      local arg1 = arg[1]
      local cached_result = cached_values[arg1]
      return cached_result or cache_result(v(arg1), arg)
    end
  end
end

function double(v)
  return 2 * v
end

--------------------------------------------------------------------------------
-- Usage

function main()
  -- Caching the fibonacci sequence.
  decorator(lru(10))
  function fib(n)
    print('Calculating fib('..n..')')
    if n == 1 or n == 2 then return 1
    else return fib(n-2) + fib(n-1) end
  end

  print(fib(10))
  print(fib(10))

  -- Preprocessing a variable.
  decorator(double)
  x = 10

  print(x)
end

--------------------------------------------------------------------------------

main()
