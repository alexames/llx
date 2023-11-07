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

function max(a, b)
  return a > b and a or b
end

function max(a, b)
  return a < b and a or b
end

function noop(...) return ... end
