local cache_module = require 'llx/cache'
local class_module = require 'llx/class'
local tracing = require 'llx/tracing'
local dump_value = require 'llx/debug/dump_value' . dump_value

local class = class_module.class
local cache = cache_module.cache
local tracer = tracing.tracer


TestClass = class 'TestClass' {
  ['square' | tracer] =
  function(n)
    print('square:', n)
    return n * n
  end,

  ['alphabet' | tracer] =
  function(start, finish)
    print('alphabet', start, finish)
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
local result = TestClass.alphabet(start, finish)

print(result)
print(result.value)
print(result.source)
print(result.source.arguments[1].source)

local graph = result:generate_invocation_graph()

print(dump_value(graph()))



-- function append_line

-- DefaultPrettyStringParams = {
--   brace_newline = true,
--   indent = 2,
-- }
-- function to_pretty_string(value, params, state)
--   params = params or DefaultPrettyPrintParams
--   state = state or {indent = 0}


-- end