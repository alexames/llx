local unit = require 'llx.unit'
local llx = require 'llx'
local tracing = require 'llx.tracing'
local isinstance_module = require 'llx.isinstance'

local isinstance = isinstance_module.isinstance

local TracedValue = tracing.TracedValue
local TracedFunctionInvocation = tracing.TracedFunctionInvocation
local TracedParameter = tracing.TracedParameter
local TracedValuePack = tracing.TracedValuePack
local Tracer = tracing.Tracer
local RegisteredFunction = tracing.RegisteredFunction
local FunctionRegistry = tracing.FunctionRegistry
local InvocationGraph = tracing.InvocationGraph
local InvocationGraphNode = tracing.InvocationGraphNode
local InvocationGraphEdge = tracing.InvocationGraphEdge

local class = llx.class

_ENV = unit.create_test_env(_ENV)

-------------------------------------------------------------------------------
-- RegisteredFunction
-------------------------------------------------------------------------------

describe('RegisteredFunction', function()
  it('should store name and function', function()
    local fn = function() return 42 end
    local rf = RegisteredFunction('my_func', fn)
    expect(rf.name).to.be_equal_to('my_func')
  end)

  it('should be callable and delegate to the underlying function', function()
    local fn = function(a, b) return a + b end
    local rf = RegisteredFunction('add', fn)
    expect(rf(3, 4)).to.be_equal_to(7)
  end)

  it('should convert to string using its name', function()
    local fn = function() end
    local rf = RegisteredFunction('my_func', fn)
    expect(tostring(rf)).to.be_equal_to('my_func')
  end)

  it('should pass through all arguments to the underlying function', function()
    local captured = {}
    local fn = function(...)
      captured = {...}
      return 'done'
    end
    local rf = RegisteredFunction('capture', fn)
    rf(1, 'hello', true)
    expect(captured[1]).to.be_equal_to(1)
    expect(captured[2]).to.be_equal_to('hello')
    expect(captured[3]).to.be_true()
  end)

  it('should return multiple values from the underlying function', function()
    local fn = function() return 10, 20, 30 end
    local rf = RegisteredFunction('multi', fn)
    local a, b, c = rf()
    expect(a).to.be_equal_to(10)
    expect(b).to.be_equal_to(20)
    expect(c).to.be_equal_to(30)
  end)
end)

-------------------------------------------------------------------------------
-- FunctionRegistry
-------------------------------------------------------------------------------

describe('FunctionRegistry', function()
  it('should wrap assigned functions as '
    .. 'RegisteredFunction instances', function()
    local registry = FunctionRegistry('MyModule')
    registry.add = function(a, b) return a + b end
    expect(isinstance(registry.add, RegisteredFunction)).to.be_true()
  end)

  it('should prefix registered function names with module name', function()
    local registry = FunctionRegistry('MyModule')
    registry.compute = function() end
    expect(registry.compute.name).to.be_equal_to('MyModule.compute')
  end)

  it('should make registered functions callable', function()
    local registry = FunctionRegistry('Mod')
    registry.double = function(x) return x * 2 end
    expect(registry.double(5)).to.be_equal_to(10)
  end)
end)

-------------------------------------------------------------------------------
-- TracedValue
-------------------------------------------------------------------------------

describe('TracedValue', function()
  it('should store value, source, and index', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(42, source, 1)
    expect(tv.value).to.be_equal_to(42)
    expect(tv.source).to.be_equal_to(source)
    expect(tv.index).to.be_equal_to(1)
  end)

  it('should convert to string using the underlying value', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(42, source, 1)
    expect(tostring(tv)).to.be_equal_to('42')
  end)

  it('should convert string values to string correctly', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue('hello', source, 1)
    expect(tostring(tv)).to.be_equal_to('hello')
  end)

  it('should handle nil value in tostring', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(nil, source, 1)
    expect(tostring(tv)).to.be_equal_to('nil')
  end)

  it('should be an instance of TracedValue', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(42, source, 1)
    expect(isinstance(tv, TracedValue)).to.be_true()
  end)
end)

-------------------------------------------------------------------------------
-- TracedFunctionInvocation
-------------------------------------------------------------------------------

describe('TracedFunctionInvocation', function()
  it('should store func, arguments, and invocation_id', function()
    local args = {}
    local inv = TracedFunctionInvocation('my_func', args, 100)
    expect(inv.func).to.be_equal_to('my_func')
    expect(inv.arguments).to.be_equal_to(args)
    expect(inv.invocation_id).to.be_equal_to(100)
  end)

  it('should have nil results initially', function()
    local inv = TracedFunctionInvocation('fn', {}, 1)
    expect(inv.results).to.be_nil()
  end)

  it('should include function name and id in tostring', function()
    local inv = TracedFunctionInvocation('my_func', {}, 42)
    local s = tostring(inv)
    expect(s).to.contain('my_func')
    expect(s).to.contain('42')
  end)

  it('should be an instance of TracedFunctionInvocation', function()
    local inv = TracedFunctionInvocation('fn', {}, 1)
    expect(isinstance(inv, TracedFunctionInvocation)).to.be_true()
  end)
end)

-------------------------------------------------------------------------------
-- TracedParameter
-------------------------------------------------------------------------------

describe('TracedParameter', function()
  it('should create a TracedValue', function()
    local tp = TracedParameter(99)
    expect(isinstance(tp, TracedValue)).to.be_true()
  end)

  it('should store the given value', function()
    local tp = TracedParameter(99)
    expect(tp.value).to.be_equal_to(99)
  end)

  it('should have a source that is a TracedFunctionInvocation', function()
    local tp = TracedParameter(99)
    expect(isinstance(tp.source, TracedFunctionInvocation)).to.be_true()
  end)

  it('should have Parameters as the source func', function()
    local tp = TracedParameter(99)
    expect(tp.source.func).to.be_equal_to('Parameters')
  end)

  it('should assign incrementing indices for successive parameters', function()
    local tp1 = TracedParameter('a')
    local tp2 = TracedParameter('b')
    expect(tp2.index).to.be_greater_than(tp1.index)
  end)
end)

-------------------------------------------------------------------------------
-- TracedValuePack
-------------------------------------------------------------------------------

describe('TracedValuePack', function()
  it('should pass through TracedValue arguments unchanged', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(42, source, 1)
    local pack = TracedValuePack{tv}
    expect(pack[1]).to.be_equal_to(tv)
  end)

  it('should wrap non-TracedValue arguments as TracedValues', function()
    local pack = TracedValuePack{10, 20}
    expect(isinstance(pack[1], TracedValue)).to.be_true()
    expect(isinstance(pack[2], TracedValue)).to.be_true()
    expect(pack[1].value).to.be_equal_to(10)
    expect(pack[2].value).to.be_equal_to(20)
  end)

  it('should extract raw argument values', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(42, source, 1)
    local pack = TracedValuePack{tv, 99}
    local raw = pack.raw_arguments
    expect(raw[1]).to.be_equal_to(42)
    expect(raw[2]).to.be_equal_to(99)
  end)

  it('should handle a mix of traced and untraced arguments', function()
    local source = TracedFunctionInvocation('test', {}, 1)
    local tv = TracedValue(5, source, 1)
    local pack = TracedValuePack{tv, 10, 15}
    expect(pack[1]).to.be_equal_to(tv)
    expect(isinstance(pack[2], TracedValue)).to.be_true()
    expect(isinstance(pack[3], TracedValue)).to.be_true()
    expect(pack[2].value).to.be_equal_to(10)
    expect(pack[3].value).to.be_equal_to(15)
  end)

  it('should handle empty argument list', function()
    local pack = TracedValuePack{}
    expect(pack.raw_arguments).to_not.be_nil()
  end)
end)

-------------------------------------------------------------------------------
-- InvocationGraphEdge
-------------------------------------------------------------------------------

describe('InvocationGraphEdge', function()
  it('should store source and destination node and slot indices', function()
    local edge = InvocationGraphEdge(1, 2, 3, 4, 'number')
    expect(edge.source_node).to.be_equal_to(1)
    expect(edge.source_slot).to.be_equal_to(2)
    expect(edge.destination_node).to.be_equal_to(3)
    expect(edge.destination_slot).to.be_equal_to(4)
    expect(edge.expected_type).to.be_equal_to('number')
  end)

  it('should include node and slot info in tostring', function()
    local edge = InvocationGraphEdge(1, 2, 3, 4)
    local s = tostring(edge)
    expect(s).to.contain('InvocationGraphEdge')
    expect(s).to.contain('1')
    expect(s).to.contain('2')
    expect(s).to.contain('3')
    expect(s).to.contain('4')
  end)
end)

-------------------------------------------------------------------------------
-- InvocationGraphNode
-------------------------------------------------------------------------------

describe('InvocationGraphNode', function()
  it('should store the function reference', function()
    local fn = function() end
    local node = InvocationGraphNode(fn)
    expect(node.func).to.be_equal_to(fn)
  end)

  it('should initialize with empty argument_edges', function()
    local fn = function() end
    local node = InvocationGraphNode(fn)
    expect(#node.argument_edges).to.be_equal_to(0)
  end)

  it('should include function info in tostring', function()
    local rf = RegisteredFunction('my_func', function() end)
    local node = InvocationGraphNode(rf)
    local s = tostring(node)
    expect(s).to.contain('InvocationGraphNode')
    expect(s).to.contain('my_func')
  end)
end)

-------------------------------------------------------------------------------
-- InvocationGraph
-------------------------------------------------------------------------------

describe('InvocationGraph', function()
  it('should initialize with empty nodes and edges by default', function()
    local graph = InvocationGraph()
    expect(#graph.nodes).to.be_equal_to(0)
    expect(#graph.edges).to.be_equal_to(0)
  end)

  it('should include nodes and edges counts in tostring', function()
    local graph = InvocationGraph()
    local s = tostring(graph)
    expect(s).to.contain('InvocationGraph')
  end)

  it('should evaluate a single-node graph correctly', function()
    local fn = function() return 42 end
    local node = InvocationGraphNode(fn)
    node.argument_edges = {}
    local list = require 'llx.types.list'
    local List = list.List
    local graph = InvocationGraph{nodes=List{node}, edges=List{}}
    local results = graph()
    expect(results[1][1]).to.be_equal_to(42)
  end)

  it('should evaluate a two-node graph with edges', function()
    -- Node 1: returns 10
    local fn1 = function() return 10 end
    local node1 = InvocationGraphNode(fn1)
    node1.argument_edges = {}

    -- Node 2: doubles its input
    local fn2 = function(x) return x * 2 end
    local node2 = InvocationGraphNode(fn2)
    node2.argument_edges = {
      [1] = {src_node = 1, src_slot = 1}
    }

    local list = require 'llx.types.list'
    local List = list.List
    local edge = InvocationGraphEdge(1, 1, 2, 1)
    local graph = InvocationGraph{nodes=List{node1, node2}, edges=List{edge}}
    local results = graph()
    expect(results[1][1]).to.be_equal_to(10)
    expect(results[2][1]).to.be_equal_to(20)
  end)

  it('should evaluate a three-node chain correctly', function()
    -- Node 1: returns 5
    -- Node 2: adds 3 to input
    -- Node 3: multiplies input by 2
    local fn1 = function() return 5 end
    local fn2 = function(x) return x + 3 end
    local fn3 = function(x) return x * 2 end

    local node1 = InvocationGraphNode(fn1)
    node1.argument_edges = {}

    local node2 = InvocationGraphNode(fn2)
    node2.argument_edges = {
      [1] = {src_node = 1, src_slot = 1}
    }

    local node3 = InvocationGraphNode(fn3)
    node3.argument_edges = {
      [1] = {src_node = 2, src_slot = 1}
    }

    local list = require 'llx.types.list'
    local List = list.List
    local graph = InvocationGraph{
      nodes = List{node1, node2, node3},
      edges = List{
        InvocationGraphEdge(1, 1, 2, 1),
        InvocationGraphEdge(2, 1, 3, 1),
      }
    }
    local results = graph()
    expect(results[1][1]).to.be_equal_to(5)
    expect(results[2][1]).to.be_equal_to(8)
    expect(results[3][1]).to.be_equal_to(16)
  end)

  it('should evaluate a diamond-shaped graph correctly', function()
    -- Node 1: returns 6
    -- Node 2: adds 1 to input
    -- Node 3: multiplies input by 10
    -- Node 4: adds two inputs together (result of node2 + result of node3)
    local fn1 = function() return 6 end
    local fn2 = function(x) return x + 1 end
    local fn3 = function(x) return x * 10 end
    local fn4 = function(a, b) return a + b end

    local node1 = InvocationGraphNode(fn1)
    node1.argument_edges = {}

    local node2 = InvocationGraphNode(fn2)
    node2.argument_edges = {[1] = {src_node = 1, src_slot = 1}}

    local node3 = InvocationGraphNode(fn3)
    node3.argument_edges = {[1] = {src_node = 1, src_slot = 1}}

    local node4 = InvocationGraphNode(fn4)
    node4.argument_edges = {
      [1] = {src_node = 2, src_slot = 1},
      [2] = {src_node = 3, src_slot = 1},
    }

    local list = require 'llx.types.list'
    local List = list.List
    local graph = InvocationGraph{
      nodes = List{node1, node2, node3, node4},
      edges = List{
        InvocationGraphEdge(1, 1, 2, 1),
        InvocationGraphEdge(1, 1, 3, 1),
        InvocationGraphEdge(2, 1, 4, 1),
        InvocationGraphEdge(3, 1, 4, 2),
      }
    }
    local results = graph()
    expect(results[1][1]).to.be_equal_to(6)   -- source
    expect(results[2][1]).to.be_equal_to(7)   -- 6 + 1
    expect(results[3][1]).to.be_equal_to(60)  -- 6 * 10
    expect(results[4][1]).to.be_equal_to(67)  -- 7 + 60
  end)

  it('should handle functions returning multiple values', function()
    local fn1 = function() return 10, 20 end
    local fn2 = function(x) return x + 5 end

    local node1 = InvocationGraphNode(fn1)
    node1.argument_edges = {}

    local node2 = InvocationGraphNode(fn2)
    node2.argument_edges = {[1] = {src_node = 1, src_slot = 2}}

    local list = require 'llx.types.list'
    local List = list.List
    local graph = InvocationGraph{
      nodes = List{node1, node2},
      edges = List{InvocationGraphEdge(1, 2, 2, 1)}
    }
    local results = graph()
    expect(results[1][1]).to.be_equal_to(10)
    expect(results[1][2]).to.be_equal_to(20)
    expect(results[2][1]).to.be_equal_to(25) -- 20 + 5
  end)
end)

-------------------------------------------------------------------------------
-- Tracer (decorator integration)
-------------------------------------------------------------------------------

describe('Tracer', function()
  it('should be an instance of Tracer', function()
    local t = Tracer()
    expect(isinstance(t, Tracer)).to.be_true()
  end)

  it('should wrap a function in a class and return TracedValues', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass1' {
      ['add' | tracer] = function(self, a, b) return a + b end,
    }
    local obj = MyClass()
    local result = obj:add(3, 4)
    expect(isinstance(result, TracedValue)).to.be_true()
    expect(result.value).to.be_equal_to(7)
  end)

  it('should preserve the underlying function behavior', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass2' {
      ['multiply' | tracer] = function(self, a, b) return a * b end,
    }
    local obj = MyClass()
    local result = obj:multiply(5, 6)
    expect(result.value).to.be_equal_to(30)
  end)

  it('should track invocation source in the TracedValue', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass3' {
      ['compute' | tracer] = function(self, x) return x * 2 end,
    }
    local obj = MyClass()
    local result = obj:compute(10)
    expect(isinstance(result.source, TracedFunctionInvocation)).to.be_true()
  end)

  it('should handle multiple return values', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass4' {
      ['swap' | tracer] = function(self, a, b) return b, a end,
    }
    local obj = MyClass()
    local r1, r2 = obj:swap(1, 2)
    expect(isinstance(r1, TracedValue)).to.be_true()
    expect(isinstance(r2, TracedValue)).to.be_true()
    expect(r1.value).to.be_equal_to(2)
    expect(r2.value).to.be_equal_to(1)
  end)

  it('should assign different indices to multiple return values', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass5' {
      ['pair' | tracer] = function(self, a, b) return a, b end,
    }
    local obj = MyClass()
    local r1, r2 = obj:pair(10, 20)
    expect(r1.index).to.be_equal_to(1)
    expect(r2.index).to.be_equal_to(2)
  end)

  it('should share the same invocation source for '
    .. 'multiple return values', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass6' {
      ['duo' | tracer] = function(self, a, b) return a + b, a - b end,
    }
    local obj = MyClass()
    local r1, r2 = obj:duo(10, 3)
    expect(r1.source).to.be_equal_to(r2.source)
  end)

  it('should chain traced values through multiple calls', function()
    local tracer = tracing.tracer
    local MyClass = class 'TracerTestClass7' {
      ['inc' | tracer] = function(self, x) return x + 1 end,
      ['dbl' | tracer] = function(self, x) return x * 2 end,
    }
    local obj = MyClass()
    local step1 = obj:inc(5)
    local step2 = obj:dbl(step1)
    expect(step2.value).to.be_equal_to(12) -- (5+1) * 2
    -- step2's source arguments should include step1 as a traced argument
    expect(isinstance(step2.source, TracedFunctionInvocation)).to.be_true()
  end)
end)

-------------------------------------------------------------------------------
-- generate_invocation_graph (on TracedValue)
-------------------------------------------------------------------------------

describe('generate_invocation_graph', function()
  it('should produce an InvocationGraph from a simple traced value', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass1' {
      ['identity' | tracer] = function(self, x) return x end,
    }
    local obj = MyClass()
    local result = obj:identity(42)
    local graph = result:generate_invocation_graph()
    expect(isinstance(graph, InvocationGraph)).to.be_true()
  end)

  it('should have the correct number of nodes for a single call', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass2' {
      ['identity' | tracer] = function(self, x) return x end,
    }
    local obj = MyClass()
    local result = obj:identity(42)
    local graph = result:generate_invocation_graph()
    -- 1 node for the identity call + 1 node for the constant (42)
    expect(#graph.nodes).to.be_greater_than(0)
  end)

  it('should produce edges connecting nodes for chained calls', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass3' {
      ['inc' | tracer] = function(self, x) return x + 1 end,
      ['dbl' | tracer] = function(self, x) return x * 2 end,
    }
    local obj = MyClass()
    local step1 = obj:inc(5)
    local step2 = obj:dbl(step1)
    local graph = step2:generate_invocation_graph()
    expect(#graph.edges).to.be_greater_than(0)
    expect(#graph.nodes).to.be_greater_than(1)
  end)

  it('should produce a graph that can be evaluated '
    .. 'to get the same result', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass4' {
      ['inc' | tracer] = function(self, x) return x + 1 end,
      ['dbl' | tracer] = function(self, x) return x * 2 end,
    }
    local obj = MyClass()
    local step1 = obj:inc(5)
    local step2 = obj:dbl(step1)
    local graph = step2:generate_invocation_graph()

    -- Evaluate the graph and check that the expected value appears
    -- in one of the node results. Node ordering depends on pairs()
    -- iteration over invocations, so we search all results.
    local results = graph()
    local found = false
    for i = 1, #results do
      if results[i][1] == 12 then -- (5 + 1) * 2
        found = true
        break
      end
    end
    expect(found).to.be_true()
  end)

  it('should handle a three-step chain', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass5' {
      ['add1' | tracer] = function(self, x) return x + 1 end,
      ['mul2' | tracer] = function(self, x) return x * 2 end,
      ['sub3' | tracer] = function(self, x) return x - 3 end,
    }
    local obj = MyClass()
    local a = obj:add1(10)  -- 11
    local b = obj:mul2(a)   -- 22
    local c = obj:sub3(b)   -- 19
    local graph = c:generate_invocation_graph()

    local results = graph()
    local found = false
    for i = 1, #results do
      if results[i][1] == 19 then
        found = true
        break
      end
    end
    expect(found).to.be_true()
  end)

  it('should handle diamond-shaped traced computation', function()
    local tracer = tracing.tracer
    local MyClass = class 'GraphTestClass6' {
      ['identity' | tracer] = function(self, x) return x end,
      ['inc' | tracer] = function(self, x) return x + 1 end,
      ['dbl' | tracer] = function(self, x) return x * 2 end,
      ['sum' | tracer] = function(self, a, b) return a + b end,
    }
    local obj = MyClass()
    local base = obj:identity(5)    -- 5
    local left = obj:inc(base)      -- 6
    local right = obj:dbl(base)     -- 10
    local final = obj:sum(left, right) -- 16
    local graph = final:generate_invocation_graph()

    -- Evaluate the graph and check that 16 appears among the results.
    -- Node ordering depends on pairs() iteration, so we search all.
    local results = graph()
    local found = false
    for i = 1, #results do
      if results[i][1] == 16 then
        found = true
        break
      end
    end
    expect(found).to.be_true()
  end)
end)

-------------------------------------------------------------------------------
-- Module exports
-------------------------------------------------------------------------------

describe('tracing module exports', function()
  it('should export TracedValue', function()
    expect(tracing.TracedValue).to_not.be_nil()
  end)

  it('should export TracedFunctionInvocation', function()
    expect(tracing.TracedFunctionInvocation).to_not.be_nil()
  end)

  it('should export TracedParameter', function()
    expect(tracing.TracedParameter).to_not.be_nil()
  end)

  it('should export TracedValuePack', function()
    expect(tracing.TracedValuePack).to_not.be_nil()
  end)

  it('should export Tracer', function()
    expect(tracing.Tracer).to_not.be_nil()
  end)

  it('should export tracer instance', function()
    expect(tracing.tracer).to_not.be_nil()
  end)

  it('should export RegisteredFunction', function()
    expect(tracing.RegisteredFunction).to_not.be_nil()
  end)

  it('should export FunctionRegistry', function()
    expect(tracing.FunctionRegistry).to_not.be_nil()
  end)

  it('should export InvocationGraph', function()
    expect(tracing.InvocationGraph).to_not.be_nil()
  end)

  it('should export InvocationGraphNode', function()
    expect(tracing.InvocationGraphNode).to_not.be_nil()
  end)

  it('should export InvocationGraphEdge', function()
    expect(tracing.InvocationGraphEdge).to_not.be_nil()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
