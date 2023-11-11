local String = string

local metatable = {}

function metatable:__call(v)
  return v and tostring(v) or ''
end;

function metatable:__tostring()
  return 'String'
end

String.__name = 'String'

function String:__isinstance(v)
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
  return self:sub(i, i)
end

local string_metatable = getmetatable('')

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

function string_metatable:__shl(n)
  if n < 0 then return self >> n end
  return self:sub(n + 1) .. self:sub(1, n)
end

function string_metatable:__shr(n)
  if n < 0 then return self << n end
  return self:sub(-(n)) .. self:sub(1, -(n + 1))
end

return setmetatable(String, metatable)