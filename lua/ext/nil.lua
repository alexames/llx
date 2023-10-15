nil_table = setmetatable({
  __name = 'nil';

  isinstance = function(v)
    return type(v) == 'nil'
  end
}, {
  __tostring = function() return 'nil' end;
})

return nil_table