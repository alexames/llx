Nil = setmetatable({
  __name = 'nil';

  isinstance = function(v)
    return type(v) == 'nil'
  end;
}, {
  __tostring = function() return 'Nil' end;
})

return Nil
