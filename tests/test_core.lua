-- Tests for llx.core module
local core = require 'llx.core'
local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.functional'

_ENV = unit.create_test_env(_ENV)

describe('getmetafield', function()
  it('should return nil for tables without metatable', function()
    local t = {}
    expect(core.getmetafield(t, '__tostring')).to.be_nil()
  end)

  it('should return nil for non-existent metafield', function()
    local t = setmetatable({}, {})
    expect(core.getmetafield(t, '__tostring')).to.be_nil()
  end)

  it('should return metafield value when present', function()
    local tostring_fn = function() return 'test' end
    local t = setmetatable({}, {__tostring = tostring_fn})
    expect(core.getmetafield(t, '__tostring')).to.be_equal_to(tostring_fn)
  end)

  it('should work with __index metafield', function()
    local index_table = {foo = 'bar'}
    local t = setmetatable({}, {__index = index_table})
    expect(core.getmetafield(t, '__index')).to.be_equal_to(index_table)
  end)
end)

describe('is_callable', function()
  it('should return true for functions', function()
    expect(core.is_callable(function() end)).to.be_truthy()
  end)

  it('should return false for numbers', function()
    expect(core.is_callable(42)).to.be_falsy()
  end)

  it('should return false for strings', function()
    expect(core.is_callable('hello')).to.be_falsy()
  end)

  it('should return false for tables without __call', function()
    expect(core.is_callable({})).to.be_falsy()
  end)

  it('should return true for tables with __call', function()
    local callable_table = setmetatable({}, {
      __call = function() return 'called' end
    })
    expect(core.is_callable(callable_table)).to.be_truthy()
  end)

  it('should return false for nil', function()
    expect(core.is_callable(nil)).to.be_falsy()
  end)
end)

describe('cmp', function()
  it('should return 0 for equal values', function()
    expect(core.cmp(5, 5)).to.be_equal_to(0)
  end)

  it('should return -1 when first is less', function()
    expect(core.cmp(3, 7)).to.be_equal_to(-1)
  end)

  it('should return 1 when first is greater', function()
    expect(core.cmp(10, 2)).to.be_equal_to(1)
  end)

  it('should work with strings', function()
    expect(core.cmp('apple', 'banana')).to.be_equal_to(-1)
    expect(core.cmp('cherry', 'apple')).to.be_equal_to(1)
    expect(core.cmp('dog', 'dog')).to.be_equal_to(0)
  end)

  it('should work with negative numbers', function()
    expect(core.cmp(-5, -3)).to.be_equal_to(-1)
    expect(core.cmp(-2, -8)).to.be_equal_to(1)
  end)
end)

describe('lesser', function()
  it('should return first when first is smaller', function()
    expect(core.lesser(3, 7)).to.be_equal_to(3)
  end)

  it('should return second when second is smaller', function()
    expect(core.lesser(10, 5)).to.be_equal_to(5)
  end)

  it('should be stable: return first argument when equal', function()
    local a = {value = 5}
    local b = {value = 5}
    local mt = {__lt = function(x, y) return x.value < y.value end}
    setmetatable(a, mt)
    setmetatable(b, mt)
    expect(rawequal(core.lesser(a, b), a)).to.be_truthy()
  end)

  it('should work with negative numbers', function()
    expect(core.lesser(-10, -5)).to.be_equal_to(-10)
  end)

  it('should work with zero', function()
    expect(core.lesser(0, 1)).to.be_equal_to(0)
  end)
end)

describe('greater', function()
  it('should return first when first is larger', function()
    expect(core.greater(10, 3)).to.be_equal_to(10)
  end)

  it('should return second when second is larger', function()
    expect(core.greater(2, 8)).to.be_equal_to(8)
  end)

  it('should be stable: return second argument when equal', function()
    local a = {value = 5}
    local b = {value = 5}
    local mt = {__lt = function(x, y) return x.value < y.value end}
    setmetatable(a, mt)
    setmetatable(b, mt)
    expect(rawequal(core.greater(a, b), b)).to.be_truthy()
  end)

  it('should work with negative numbers', function()
    expect(core.greater(-10, -5)).to.be_equal_to(-5)
  end)
end)

describe('even', function()
  it('should return true for 0', function()
    expect(core.even(0)).to.be_truthy()
  end)

  it('should return true for positive even numbers', function()
    expect(core.even(2)).to.be_truthy()
    expect(core.even(4)).to.be_truthy()
    expect(core.even(100)).to.be_truthy()
  end)

  it('should return false for positive odd numbers', function()
    expect(core.even(1)).to.be_falsy()
    expect(core.even(3)).to.be_falsy()
    expect(core.even(99)).to.be_falsy()
  end)

  it('should return true for negative even numbers', function()
    expect(core.even(-2)).to.be_truthy()
    expect(core.even(-4)).to.be_truthy()
  end)

  it('should return false for negative odd numbers', function()
    expect(core.even(-1)).to.be_falsy()
    expect(core.even(-3)).to.be_falsy()
  end)
end)

describe('odd', function()
  it('should return false for 0', function()
    expect(core.odd(0)).to.be_falsy()
  end)

  it('should return true for positive odd numbers', function()
    expect(core.odd(1)).to.be_truthy()
    expect(core.odd(3)).to.be_truthy()
    expect(core.odd(99)).to.be_truthy()
  end)

  it('should return false for positive even numbers', function()
    expect(core.odd(2)).to.be_falsy()
    expect(core.odd(4)).to.be_falsy()
    expect(core.odd(100)).to.be_falsy()
  end)

  it('should return true for negative odd numbers', function()
    expect(core.odd(-1)).to.be_truthy()
    expect(core.odd(-3)).to.be_truthy()
  end)
end)

describe('nonnil', function()
  it('should return false for nil', function()
    expect(core.nonnil(nil)).to.be_falsy()
  end)

  it('should return true for 0', function()
    expect(core.nonnil(0)).to.be_truthy()
  end)

  it('should return true for false', function()
    expect(core.nonnil(false)).to.be_truthy()
  end)

  it('should return true for empty string', function()
    expect(core.nonnil('')).to.be_truthy()
  end)

  it('should return true for empty table', function()
    expect(core.nonnil({})).to.be_truthy()
  end)

  it('should return true for numbers', function()
    expect(core.nonnil(42)).to.be_truthy()
  end)
end)

describe('noop', function()
  it('should return single argument unchanged', function()
    expect(core.noop(42)).to.be_equal_to(42)
  end)

  it('should return multiple arguments unchanged', function()
    local a, b, c = core.noop(1, 2, 3)
    expect(a).to.be_equal_to(1)
    expect(b).to.be_equal_to(2)
    expect(c).to.be_equal_to(3)
  end)

  it('should return nil when called with no arguments', function()
    expect(core.noop()).to.be_nil()
  end)

  it('should handle nil arguments', function()
    local a, b = core.noop(nil, 'test')
    expect(a).to.be_nil()
    expect(b).to.be_equal_to('test')
  end)
end)

describe('tovalue', function()
  it('should evaluate simple numeric expression', function()
    expect(core.tovalue('1 + 2')).to.be_equal_to(3)
  end)

  it('should evaluate multiplication', function()
    expect(core.tovalue('5 * 4')).to.be_equal_to(20)
  end)

  it('should evaluate string literal', function()
    expect(core.tovalue('"hello"')).to.be_equal_to('hello')
  end)

  it('should evaluate boolean', function()
    expect(core.tovalue('true')).to.be_truthy()
    expect(core.tovalue('false')).to.be_falsy()
  end)

  it('should evaluate table constructor', function()
    local result = core.tovalue('{1, 2, 3}')
    expect(result[1]).to.be_equal_to(1)
    expect(result[2]).to.be_equal_to(2)
    expect(result[3]).to.be_equal_to(3)
  end)

  it('should evaluate nil', function()
    expect(core.tovalue('nil')).to.be_nil()
  end)

  it('should error on invalid expression', function()
    expect(function() core.tovalue('if') end).to.throw()
  end)

  it('should error on non-string argument', function()
    expect(function() core.tovalue(42) end).to.throw()
  end)
end)

describe('values', function()
  it('should iterate over table values', function()
    local t = {a = 1, b = 2, c = 3}
    local vals = {}
    for v in core.values(t) do
      table.insert(vals, v)
    end
    table.sort(vals)
    expect(#vals).to.be_equal_to(3)
    expect(vals[1]).to.be_equal_to(1)
    expect(vals[2]).to.be_equal_to(2)
    expect(vals[3]).to.be_equal_to(3)
  end)

  it('should handle empty table', function()
    local t = {}
    local count = 0
    for v in core.values(t) do
      count = count + 1
    end
    expect(count).to.be_equal_to(0)
  end)
end)

describe('ivalues', function()
  it('should iterate over array values', function()
    local t = {'a', 'b', 'c'}
    local values = {}
    for v in core.ivalues(t) do
      table.insert(values, v)
    end
    expect(#values).to.be_equal_to(3)
    expect(values[1]).to.be_equal_to('a')
    expect(values[2]).to.be_equal_to('b')
    expect(values[3]).to.be_equal_to('c')
  end)

  it('should handle empty array', function()
    local t = {}
    local count = 0
    for v in core.ivalues(t) do
      count = count + 1
    end
    expect(count).to.be_equal_to(0)
  end)

  it('should stop at first nil', function()
    local t = {1, 2, nil, 4}
    local values = {}
    for v in core.ivalues(t) do
      table.insert(values, v)
    end
    expect(#values).to.be_equal_to(2)
  end)
end)

describe('type predicates', function()
  it('is_table should detect tables', function()
    expect(llx.is_table({})).to.be_equal_to(true)
    expect(llx.is_table(1)).to.be_equal_to(false)
  end)

  it('is_string should detect strings', function()
    expect(llx.is_string('hello')).to.be_equal_to(true)
    expect(llx.is_string(1)).to.be_equal_to(false)
  end)

  it('is_number should detect numbers', function()
    expect(llx.is_number(42)).to.be_equal_to(true)
    expect(llx.is_number('42')).to.be_equal_to(false)
  end)

  it('is_function should detect functions', function()
    expect(llx.is_function(print)).to.be_equal_to(true)
    expect(llx.is_function(42)).to.be_equal_to(false)
  end)

  it('is_boolean should detect booleans', function()
    expect(llx.is_boolean(true)).to.be_equal_to(true)
    expect(llx.is_boolean(false)).to.be_equal_to(true)
    expect(llx.is_boolean(nil)).to.be_equal_to(false)
  end)

  it('is_nil should detect nil', function()
    expect(llx.is_nil(nil)).to.be_equal_to(true)
    expect(llx.is_nil(false)).to.be_equal_to(false)
  end)
end)

describe('clone', function()
  it('should shallow copy a table', function()
    local t = {a = 1, b = {c = 2}}
    local c = llx.clone(t)
    expect(c.a).to.be_equal_to(1)
    expect(c.b).to.be_equal_to(t.b)  -- same reference (shallow)
    c.a = 99
    expect(t.a).to.be_equal_to(1)  -- original unchanged
  end)

  it('should return non-table values unchanged', function()
    expect(llx.clone(42)).to.be_equal_to(42)
    expect(llx.clone('hello')).to.be_equal_to('hello')
    expect(llx.clone(true)).to.be_equal_to(true)
  end)
end)

describe('times', function()
  it('should call function n times and collect results', function()
    local result = llx.times(3, function(i) return i * 10 end)
    expect(result).to.be_equal_to(llx.List{10, 20, 30})
  end)

  it('should return empty list for n=0', function()
    local result = llx.times(0, function() return 1 end)
    expect(#result).to.be_equal_to(0)
  end)
end)

describe('cond', function()
  it('should return result of first matching predicate', function()
    local classify = llx.cond({
      {function(x) return x < 0 end, function() return 'negative' end},
      {function(x) return x == 0 end, function() return 'zero' end},
      {function() return true end, function() return 'positive' end},
    })
    expect(classify(-5)).to.be_equal_to('negative')
    expect(classify(0)).to.be_equal_to('zero')
    expect(classify(5)).to.be_equal_to('positive')
  end)

  it('should return nil when no predicate matches', function()
    local f = llx.cond({
      {function(x) return x > 100 end, function() return 'big' end},
    })
    expect(f(1)).to.be_equal_to(nil)
  end)
end)

describe('collect', function()
  it('should materialize an iterator into a List', function()
    local result = llx.collect(llx.functional.range(5))
    expect(result).to.be_equal_to(llx.List{1, 2, 3, 4})
  end)

  it('should handle empty iterator', function()
    local result = llx.collect(llx.functional.range(1))
    expect(#result).to.be_equal_to(0)
  end)
end)

describe('range_inclusive', function()
  it('should include the end value', function()
    local result = llx.List{}
    for _, v in llx.functional.range_inclusive(1, 5) do
      result:insert(v)
    end
    expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
  end)

  it('should work with step', function()
    local result = llx.List{}
    for _, v in llx.functional.range_inclusive(0, 10, 3) do
      result:insert(v)
    end
    expect(result).to.be_equal_to(llx.List{0, 3, 6, 9})
  end)

  it('should work with single argument', function()
    local result = llx.List{}
    for _, v in llx.functional.range_inclusive(3) do
      result:insert(v)
    end
    expect(result).to.be_equal_to(llx.List{1, 2, 3})
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
