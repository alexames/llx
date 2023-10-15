function_table = setmetatable({
  __name = 'function';

  isinstance = function(v)
    return type(v) == 'function'
  end
}, {
  __tostring = function() return 'boolean' end;
})

return function_table