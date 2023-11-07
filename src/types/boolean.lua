Boolean = setmetatable({
  __name = 'Boolean';

  __isinstance = function(v)
    return type(v) == 'boolean'
  end;
},{
  __call = function(self, v)
    return v ~= nil and v ~= false
  end;

  __tostring = function() return 'Boolean' end;
})

return boolean