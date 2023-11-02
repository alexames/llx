String = string

setmetatable(string, {
  __call = function(self, v)
    return v and tostring(v) or ''
  end;
})

local string_metatable = getmetatable('')

String.__name = 'String'

String.isinstance = function(v)
  return type(v) == 'string'
end

function String:join(t)
  local result = ''
  for i=1, #t do
    if i > 1 then
      result = result .. self
    end
    result = result .. tostring(t[i])
  end
  return result
end

function String:empty()
  return #self == 0
end

function String:startswith(start)
   return self:sub(1, #start) == start
end

function String:endswith(ending)
   return ending == "" or self:sub(-#ending) == ending
end

function String:__index(i, v)
  print(i)
  return self:sub(i, i)
end

function string_metatable.__index(s, k)
  if type(k) == 'number' then
    return s:sub(k, k)
  else
    return string[k]
  end
end

function string_metatable.__unm(str,i)
  return string.reverse(str)
end

function string_metatable.__mul(str,i)
  return string.rep(str, i)
end

return String
