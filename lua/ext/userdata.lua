userdata = setmetatable({
  __name = 'userdata';

  isinstance = function(v)
    return type(v) == 'userdata'
  end;
}, {
  __tostring = function() return 'userdata' end;
})

return userdata