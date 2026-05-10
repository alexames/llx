-- examples/04_exceptions.lua
-- Structured exceptions and try/catch.

local llx = require 'llx'
local exceptions = llx.exceptions
local try = require 'llx.flow_control.trycatch'.try
local catch = require 'llx.flow_control.catch'.catch

-- Built-in exception types. The codebase uses ValueException
-- (not ValueError); other names are spelled as you'd expect.
local ValueException = exceptions.ValueException
local TypeError = exceptions.TypeError
local IndexError = exceptions.IndexError

-- Raise an exception via standard error().
local function divide(a, b)
  if b == 0 then
    error(ValueException('division by zero'))
  end
  return a / b
end

-- Catch with try/catch. The first entry is the body; subsequent
-- entries are catch(Type, handler) clauses checked in order.
try {
  function()
    print(divide(10, 2))     --> 5.0
    print(divide(10, 0))     -- raises ValueException
  end;
  catch(ValueException, function(e)
    print('caught ValueException:', e)
  end);
}

-- Multiple catch clauses dispatch on exception type.
local function lookup(t, key)
  if t[key] == nil then
    error(IndexError('missing key: ' .. tostring(key)))
  end
  if type(t[key]) ~= 'string' then
    error(TypeError('value is not a string'))
  end
  return t[key]
end

try {
  function() return lookup({a = 'x'}, 'b') end;
  catch(IndexError, function(e)
    print('caught IndexError:', e)
  end);
  catch(TypeError, function(e)
    print('caught TypeError:', e)
  end);
}

-- Define your own exception subclass.
local NetworkError = llx.class 'NetworkError' : extends(exceptions.Exception) {
  __init = function(self, host, message)
    self.Exception.__init(self, message)
    self.host = host
  end,
}

try {
  function()
    error(NetworkError('example.com', 'timeout'))
  end;
  catch(NetworkError, function(e)
    print(string.format('NetworkError on %s: %s', e.host, e.what))
  end);
}
