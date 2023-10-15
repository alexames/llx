thread = setmetatable({
  __name = 'thread';

  isinstance = function(v)
    return type(v) == 'thread'
  end;
}, {
  __tostring = function() return 'thread' end;
})

return thread