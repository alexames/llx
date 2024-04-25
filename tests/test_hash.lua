-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx' . class
local environment = require 'llx/environment'
local Tuple = require 'llx/tuple' . Tuple
local hash = require 'llx/hash'
local Decorator = require 'llx/decorator' . Decorator
local isinstance_module = require 'llx/isinstance'
local getclass_module = require 'llx/getclass'

local _ENV, _M = environment.create_module_environment()

local isinstance = isinstance_module.isinstance
local getclass = getclass_module.getclass

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

TracedValue = class 'TracedValue' {
  __init = function(self, value, source, index)
    self.value = value
    self.source = source or '<given>'
    self.index = index
  end,

  __tostring = function(self)
    return tostring(self.value)
    -- return string.format('%s: from %s, %s', self.value, self.source, self.index)
  end,

  __repr = function(self)
    return tostring(self.value)
  end,
}

TracedFunctionInvocation = class 'TracedFunctionInvocation' {
  __init = function(self, fn, arguments)
    self.fn = fn
    self.arguments = arguments
    self.results = nil
  end,

  __tostring = function(self)
    local result = 'TracedFunctionInvocation(' .. tostring(self.fn)
    if #self.arguments > 0 then
      result = result  .. ',' .. table.concat(self.arguments, ',')
    end
    return result .. ')'
  end,
}

Tracer = class 'Tracer' : extends(Decorator) {
  class_registries = {},

  _process_arguments = function(args)
      local raw_arguments = {}
      local traced_arguments = {}
      for i, v in ipairs(args) do
        if isinstance(v, TracedValue) then
          raw_arguments[i] = v.value
          traced_arguments[i] = v
        else
          raw_arguments[i] = v
          traced_arguments[i] = TracedValue(v)
        end
      end
      return raw_arguments, traced_arguments
  end,

  _getfunctionregistry = function(class_table)
    local registry = Tracer.class_registries[class_table]
    if registry == nil then
      registry = FunctionRegistry(class_table.__name)
      Tracer.class_registries[class_table] = registry
    end
    return registry
  end,

  decorate = function(self, class_table, name, value)
    -- Register the function in the registry.
    local registry = Tracer._getfunctionregistry(class_table)
    registry[name] = value
    local registered_function = registry[name]
    -- Trace the values and results.
    local function wrapped_function(...)
      local raw_arguments, traced_arguments = Tracer._process_arguments({...})
      local traced_function = TracedFunctionInvocation(registered_function, traced_arguments)
      local raw_results = {registered_function(table.unpack(raw_arguments))}
      local traced_results = {}
      for i, raw_result in ipairs(raw_results) do
        traced_results[i] = TracedValue(raw_result, traced_function, i)
      end
      return traced_results
    end
    return class_table, name, wrapped_function
  end,
}
local tracer = Tracer()

TestClass = class 'TestClass' {
  ['square' | tracer] =
  function(n)
    return n * n
  end,

  ['alphabet' | tracer] =
  function(start, finish)
    local result = {}
    local alpha = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
    for i=start, finish do
      table.insert(result, alpha[i])
    end
    return setmetatable(result, {__tostring = function(self) return table.concat(self, ',') end})
  end,
}

local start = TestClass.square(2)
local finish = TestClass.square(4)
local results = TestClass.alphabet(start[1], finish[1])
print(results[1].value)
print(results[1].source)
print(results[1].source.arguments[1].source)
for k, v in pairs(results[1].source.arguments) do print(k, v) end




-- ResultantValue = class 'ResultantValue' {
--   __init = function(self, function_call, result)
--   end,
-- }



-- function traced_call(registered_function, ...)
--   local result = ResultantValue(registered_function, )
--   registered_function

-- end

-- local result = traced_call(registry.alphabetkkkkkkkkkkkkk)

-- registry = FunctionRegistry('registry')

-- registry.print = print
-- registry.add = function(a, b) return a + b end

-- print(registry.print)

-- fc = FunctionCall(registry.add, 1, 2)

-- print(fc)
-- print(fc())

-- registry.print('this is a test')
