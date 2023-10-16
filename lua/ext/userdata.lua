Userdata = setmetatable({
  __name = 'Userdata';

  isinstance = function(v)
    return type(v) == 'userdata'
  end;
}, {
  __tostring = function() return 'Userdata' end;
})

return Userdata