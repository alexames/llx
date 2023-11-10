Integer = setmetatable({
  __name = 'Integer';

  __isinstance = function(v)
    return math.type(v) == 'integer'
  end;
}, {
  __call = function(self, v)
    if v == nil or v == false then
      return 0
    elseif v == true then
      return 1
    else
      return tointeger(v)
    end
  end;

  __tostring = function() return 'Integer' end;
})

return Integer
