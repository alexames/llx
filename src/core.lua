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

function range(a, b, c)
  local start = b and a or 1
  local finish = b or a
  local step = c or 1
  local up = step > 0
  return function(unused, i)
    i = i + step
    if up and i < finish or i > finish then
      return i
    else
      return nil
    end
  end, nil, start - step
end

function rangelist(a, b, c)
  local result = List{}
  for i in range(a, b, c) do
    result:insert(i)
  end
  return result
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

-- like the less than (<) operation, but returns the lesser value (instead of a boolean)
function lesser(a, b)
  return a < b and a or b
end

-- like the greater than (>) operation, but returns the greater value (instead of a boolean)
function greater(a, b)
  return a > b and a or b
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
  lesser=lesser,
  greater=greater,
  noop=noop,
  tovalue=tovalue,
}
