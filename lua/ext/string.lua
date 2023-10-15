
setmetatable(string, {
  __call = function(self, v)
    return v and tostring(v) or ''
  end;

  __tostring = function() return 'string' end;
})

string.__name = 'string'

string.isinstance = function(v)
  return type(v) == 'string'
end

function string:join(t)
  local result = ''
  for i=1, #t do
    if i > 1 then
      result = result .. self
    end
    result = result .. t[i]
  end
  return result
end

function string:empty()
  return #self == 0
end

function string:startswith(start)
   return self:sub(1, #start) == start
end

function string:endswith(ending)
   return ending == "" or self:sub(-#ending) == ending
end

return string