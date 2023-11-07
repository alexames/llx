Thread = setmetatable({
  __name = 'Thread';

  __isinstance = function(v)
    return type(v) == 'thread'
  end;
}, {
  __tostring = function() return 'Thread' end;
})

return Thread
