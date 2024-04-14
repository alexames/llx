local class = require 'llx' . class
local Tuple = require 'llx/src/tuple' . Tuple
local hash = require 'llx/src/hash'

RegisteredFunction = class 'RegisteredFunction' {
  __init = function(self, name, fn)
    self.name = name
    self._fn = fn
  end,

  __call = function(self, ...)
    return self._fn(...)
  end,

  __hash = function(self, result)
    result = hash.hash_value(result, self.name)
    result = hash.hash_value(result, tostring(self._fn))
    return result
  end,

  __tostring = function(self)
    return self.name
  end,
}

FunctionRegistry = class 'FunctionRegistry' {
  __init = function(self, name)
    rawset(self, '__name', name)
  end,

  __newindex = function(self, key, value)
    assert(type(key) == 'string' and type(value) == 'function')
    rawset(self, key, RegisteredFunction(self.__name .. '.' .. key, value))
  end,
}

FunctionCall = class 'FunctionCall' {
  __init = function(self, fn, ...)
    self.fn = fn
    self.args = Tuple{...}
    self.results = nil
  end,

  __call = function(self)
    if not self.results then
      self.results = {self.fn(self.args:unpack())}
    end
    return table.unpack(self.results)
  end,

  __tostring = function(self)
    local result = 'FunctionCall(' .. tostring(self.fn)
    if #self.args > 0 then
      result = result  .. ',' .. table.concat(self.args, ',')
    end
    return result .. ')'
  end,
}

-- registry = FunctionRegistry('registry')

-- registry.print = print
-- registry.add = function(a, b) return a + b end

-- print(registry.print)

-- fc = FunctionCall(registry.add, 1, 2)

-- print(fc)
-- print(fc())



-- registry.print('this is a test')
