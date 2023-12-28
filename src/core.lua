-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

function getmetafield(t, k)
  local metatable = debug.getmetatable(t)
  return metatable and rawget(metatable, k)
end

function printf(fmt, ...)
  print(string.format(fmt, ...))
end

function script_path(level)
   return debug.getinfo((level or 1) + 1, "S").source:sub(2)
end

function main_file(level)
  return script_path((level or 1) + 1) == arg[0]
end

function metamethod_args(class, self, other)
  if isinstance(self, class) then
    return self, other
  else
    return other, self
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

function cmp(a, b)
  if a == b then return 0
  elseif a < b then return -1
  else return 1
  end
end

function reduce(list, initial_value, lambda)
  local result = initial_value
  for i, value in ipairs(list) do
    result = lambda(result, value)
  end
  return result
end

function min(list)
  return reduce(list, nil, function(a, b) return (a and a < b) and a or b end)
end

function max(list)
  return reduce(list, nil, function(a, b) return (a and a > b) and a or b end)
end

function sum(list)
  return reduce(list, 0, function(a, b) return a + b end)
end

function product(list)
  return reduce(list, 1, function(a, b) return a * b end)
end

function noop(...) return ... end

function tovalue(s)
  return load('return '.. s)()
end

return {
  getmetafield=getmetafield,
  printf=printf,
  script_path=script_path,
  main_file=main_file,
  metamethod_args=metamethod_args,
  values=values,
  ivalues=ivalues,
  cmp=cmp,
  reduce=reduce,
  max=max,
  max=max,
  sum=sum,
  product=product,
  noop=noop,
  tovalue=tovalue,
}
