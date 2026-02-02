-- Tests for llx.core module
local core = require 'llx.core'
local unit = require 'llx.unit'
local llx = require 'llx'

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

  it('should return first when equal (due to short-circuit)', function()
    expect(core.lesser(5, 5)).to.be_equal_to(5)
  end)

  it('should work with negative numbers', function()
    expect(core.lesser(-10, -5)).to.be_equal_to(-10)
  end)
end)

describe('greater', function()
  it('should return first when first is larger', function()
    expect(core.greater(10, 3)).to.be_equal_to(10)
  end)

  it('should return second when second is larger', function()
    expect(core.greater(2, 8)).to.be_equal_to(8)
  end)

  it('should return first when equal (due to short-circuit)', function()
    expect(core.greater(5, 5)).to.be_equal_to(5)
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

  it('should return true for positive odd numbers', function()
    expect(core.odd(1)).to.be_truthy()
    expect(core.odd(3)).to.be_truthy()
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

if llx.main_file() then
  unit.run_unit_tests()
end
