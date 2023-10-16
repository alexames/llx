String = string

setmetatable(string, {
  __call = function(self, v)
    return v and tostring(v) or ''
  end;

  __tostring = function() return 'String' end;
})


String.__name = 'String'

String.isinstance = function(v)
  return type(v) == 'String'
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

return String