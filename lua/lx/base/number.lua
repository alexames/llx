Number = setmetatable({
  __name = 'Number';

  isinstance = function(v)
    return type(v) == 'number'
  end;
}, {
  __call = function(self, v)
    if v == nil or v == false then
      return 0
    elseif v == true then
      return 1
    else
      return tonumber(v)
    end
  end;

  __tostring = function() return 'Number' end;
})

return Number
