number = setmetatable({
  __name = 'number';

  isinstance = function(v)
    return type(v) == 'number'
  end;
},
{
  __call = function(v)
    return tonumber(v)
  end;

  __tostring = function() return 'number' end;
})

return number