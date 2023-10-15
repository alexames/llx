boolean = setmetatable({
  __name = 'boolean';

  isinstance = function(v)
    return type(v) == 'boolean'
  end;
},{
  __call = function(v)
    return v ~= nil and v ~= false
  end;

  __tostring = function() return 'boolean' end;
})

return boolean