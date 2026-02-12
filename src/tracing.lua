-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local cache_module = require 'llx.cache'
local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'
local getclass_module = require 'llx.getclass'
local hash = require 'llx.hash'
local isinstance_module = require 'llx.isinstance'
local list = require 'llx.types.list'
local tuple = require 'llx.tuple'

local dump_value = require 'llx.debug.dump_value' . dump_value

local _ENV, _M = environment.create_module_environment()

local cache = cache_module.cache
local class = class_module.class
local Decorator = decorator.Decorator
local getclass = getclass_module.getclass
local isinstance = isinstance_module.isinstance
local List = list.List
local Tuple = tuple.Tuple

RegisteredFunction = class 'RegisteredFunction' {
  __init = function(self, name, func)
    self.name = name
    self._func = func
  end,

  __call = function(self, ...)
    return self._func(...)
  end,

  __hash = function(self, result)
    result = hash.hash_value(result, self.name)
    result = hash.hash_value(result, tostring(self._func))
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

InvocationGraphEdge = class 'InvocationGraphEdge' {
  __init = function(
      self, source_node, source_slot,
      destination_node, destination_slot,
      expected_type)
    self.source_node = source_node
    self.source_slot = source_slot
    self.destination_node = destination_node
    self.destination_slot = destination_slot
    self.expected_type = expected_type
  end,

  __tostring = function(self)
    return string.format('InvocationGraphEdge(%s, %s, %s, %s)',
      self.source_node, self.source_slot, self.destination_node,
      self.destination_slot)
  end,
}

InvocationGraphNode = class 'InvocationGraphNode' {
  __init = function(self, func)
    self.func = func
    self.argument_edges = {}
  end,

  __tostring = function(self)
    return string.format('InvocationGraphNode(%s)', self.func)
  end,
}

InvocationGraph = class 'InvocationGraph' {
  __init = function(self, args)
    self.nodes = args and args.nodes or List{}
    self.edges = args and args.edges or List{}
  end,

  __tostring = function(self)
    return string.format(
      'InvocationGraph{nodes=%s,edges=%s}', self.nodes, self.edges)
  end,

  __call = function(self, args)
    local function eval_node(results, nodes, index)
      local arguments = {}
      local node = nodes[index]
      for i, inputs in ipairs(node.argument_edges) do
        local src_node = inputs.src_node
        local src_slot = inputs.src_slot
        local node_results = results[src_node]
        if node_results == nil then
          node_results = eval_node(results, nodes, src_node)
          results[src_node] = node_results
        end
        arguments[i] = node_results[src_slot]
      end
      return {node.func(table.unpack(arguments))}
    end

    local results = {}
    for i, node in ipairs(self.nodes) do
      results[i] = results[i] or eval_node(results, self.nodes, i)
    end
    return results
  end,
}

TracedValue = class 'TracedValue' {
  __init = function(self, value, source, index)
    self.value = value
    self.source = source
    self.index = index
  end,

  __tostring = function(self)
    return tostring(self.value)
  end,

  __repr = function(self)
    return tostring(self.value)
  end,

  generate_invocation_graph = function(self)
    local graph = InvocationGraph()

    local invocations = {}
    local function collet_invocations(traced_value)
      local invocation = traced_value.source
      if invocations[invocation.invocation_id] then
        return
      end
      invocations[invocation.invocation_id] = invocation
      for i, argument in ipairs(invocation.arguments) do
        collet_invocations(argument)
      end
    end
    collet_invocations(self)
    local node_index_map = {}
    for k, invocation in pairs(invocations) do
      graph.nodes:insert(InvocationGraphNode(invocation.func))
      node_index_map[invocation] = #graph.nodes
    end
    for k, invocation in pairs(invocations) do
      for i, argument in ipairs(invocation.arguments) do
        local target_node_index = node_index_map[invocation]
        local target_node = graph.nodes[target_node_index]
        local src_node = node_index_map[argument.source]
        local src_slot = argument.index
        local dst_node = target_node_index
        local dst_slot = i
        graph.edges:insert(
          InvocationGraphEdge(
            src_node, src_slot,
            dst_node, dst_slot))
        target_node.argument_edges[i] = {src_node=src_node, src_slot=src_slot}
      end
    end
    return graph
  end,
}

TracedFunctionInvocation = class 'TracedFunctionInvocation' {
  __init = function(self, func, arguments, invocation_id)
    self.func = func
    self.arguments = arguments
    self.invocation_id = invocation_id
    self.results = nil
  end,

  __tostring = function(self)
    return string.format(
      'TracedFunctionInvocation(%s(%s), %s)', self.func,
      table.concat(self.arguments, ','), self.invocation_id)
  end,
}

local invocation_id = 1
local function get_invocation_id()
  local result = invocation_id
  invocation_id = invocation_id + 1
  return result
end

local parameters = TracedFunctionInvocation(
  'Parameters', {}, get_invocation_id())
local parameters_index = 1

function TracedParameter(value)
  local traced_value = TracedValue(value, parameters, parameters_index)
  parameters_index = parameters_index + 1
  return traced_value
end

TracedValuePack = class 'TracedValuePack' {
  __init = function(self, args)
    local constants_values = {}
    local function constants_fn() return table.unpack(constants_values) end
    local constants = TracedFunctionInvocation(
      constants_fn, {}, get_invocation_id())
    local constants_index = 1


    local raw_arguments = {}
    local traced_arguments = {}
    for i, v in ipairs(args) do
      if isinstance(v, TracedValue) then
        raw_arguments[i] = v.value
        traced_arguments[i] = v
      else
        raw_arguments[i] = v
        traced_arguments[i] = TracedValue(v, constants, constants_index)
        constants_values[constants_index] = v
        constants_index = constants_index + 1
      end
    end
    self.raw_arguments = Tuple(raw_arguments)
    self.traced_arguments = traced_arguments
  end,

  __index = function(self, k)
    return self.traced_arguments[k] or TracedValuePack.__defaultindex(self, k)
  end,
}

Tracer = class 'Tracer' : extends(Decorator) {
  class_registries = {},

  _process_arguments = function(args)
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
    -- move this to a decorator
    local registry = Tracer._getfunctionregistry(class_table)
    registry[name] = value
    local registered_function = registry[name]
    -- Trace the values and results.
    local function wrapped_function(...)
      local argument_pack = TracedValuePack{...}
      local traced_function = TracedFunctionInvocation(
        registered_function, argument_pack.traced_arguments,
        get_invocation_id())
      local raw_results =
        {registered_function(table.unpack(argument_pack.raw_arguments))}
      local traced_results = {}
      for i, raw_result in ipairs(raw_results) do
        traced_results[i] = TracedValue(raw_result, traced_function, i)
      end
      return table.unpack(traced_results)
    end
    return class_table, name, wrapped_function
  end,
}
tracer = Tracer()

return _M
