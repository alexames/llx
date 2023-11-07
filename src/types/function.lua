Function = setmetatable({
  __name = 'function';

  __isinstance = function(v)
    return type(v) == 'function'
  end
}, {
  __tostring = function() return 'Function' end;
})

return Function
