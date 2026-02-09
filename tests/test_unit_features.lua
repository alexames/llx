local unit = require 'llx.unit'
local matchers_mod = require 'llx.unit.matchers'
local test_api = require 'llx.unit.test_api'

_ENV = unit.create_test_env(_ENV)

-- Test throw matcher
describe('throw matcher', function()
  it('should pass when function throws', function()
    expect(function() error('boom') end).to.throw()
  end)

  it('should match specific error message', function()
    expect(function() error('specific error') end).to.throw('specific error')
  end)

  it('should fail when function does not throw', function()
    local ok = pcall(function()
      expect(function() return 1 end).to.throw()
    end)
    expect(ok).to.be_false()
  end)

  it('should pass to_not.throw when function succeeds', function()
    expect(function() return 1 end).to_not.throw()
  end)

  it('should fail to_not.throw when function throws', function()
    local ok = pcall(function()
      expect(function() error('oops') end).to_not.throw()
    end)
    expect(ok).to.be_false()
  end)

  it('should reject non-function argument', function()
    local ok = pcall(function()
      expect(42).to.throw()
    end)
    expect(ok).to.be_false()
  end)
end)

-- Test expect.extend (custom matchers)
describe('expect.extend', function()
  test_api.expect_extend('be_divisible_by', function(divisor)
    return function(actual)
      if type(actual) ~= 'number' or type(divisor) ~= 'number' then
        return {
          pass = false,
          actual = tostring(actual),
          positive_message = 'be divisible by',
          negative_message = 'not be divisible by',
          expected = tostring(divisor)
        }
      end
      return {
        pass = actual % divisor == 0,
        actual = tostring(actual),
        positive_message = 'be divisible by',
        negative_message = 'not be divisible by',
        expected = tostring(divisor)
      }
    end
  end)

  it('should support custom matchers', function()
    expect(10).to.be_divisible_by(5)
    expect(10).to.be_divisible_by(2)
  end)

  it('should support negated custom matchers', function()
    expect(10).to_not.be_divisible_by(3)
  end)

  it('should reject invalid matcher name type', function()
    local ok = pcall(function()
      test_api.expect_extend(123, function()
        return function()
          return {pass = true, actual = '', positive_message = '', negative_message = '', expected = ''}
        end
      end)
    end)
    expect(ok).to.be_false()
  end)

  it('should reject non-function matcher', function()
    local ok = pcall(function()
      test_api.expect_extend('bad', 'not a function')
    end)
    expect(ok).to.be_false()
  end)
end)

-- Test it.todo and it.skip
describe('todo and skip', function()
  it.todo('should support this feature later')

  it.skip('this test is skipped', function()
    error('should not run')
  end)

  it('regular test should still run', function()
    expect(true).to.be_true()
  end)
end)

-- Test it.each (parameterized tests)
describe('parameterized tests with it.each', function()
  it.each({
    {2, true},
    {3, false},
    {4, true},
    {5, false},
  })('should check if %d is even: %s', function(n, expected)
    expect(n % 2 == 0).to.be_equal_to(expected)
  end)

  it.each({1, 2, 3})('value %d should be positive', function(n)
    expect(n > 0).to.be_true()
  end)
end)

-- Test has_length for tables
describe('has_length matcher', function()
  it('should check string length', function()
    expect('hello').to.have_length(5)
  end)

  it('should check table length', function()
    expect({1, 2, 3}).to.have_length(3)
  end)

  it('should check empty table length', function()
    expect({}).to.have_length(0)
  end)

  it('should fail for wrong length', function()
    local ok = pcall(function()
      expect({1, 2}).to.have_length(5)
    end)
    expect(ok).to.be_false()
  end)
end)

-- Test match_table (deep equality)
describe('match_table matcher', function()
  it('should match identical tables', function()
    expect({a = 1, b = 2}).to.match_table({a = 1, b = 2})
  end)

  it('should match nested tables', function()
    expect({a = {b = {c = 3}}}).to.match_table({a = {b = {c = 3}}})
  end)

  it('should match arrays', function()
    expect({1, 2, 3}).to.match_table({1, 2, 3})
  end)

  it('should fail for different values', function()
    local ok = pcall(function()
      expect({a = 1}).to.match_table({a = 2})
    end)
    expect(ok).to.be_false()
  end)

  it('should fail for missing keys', function()
    local ok = pcall(function()
      expect({a = 1}).to.match_table({a = 1, b = 2})
    end)
    expect(ok).to.be_false()
  end)

  it('should fail for extra keys', function()
    local ok = pcall(function()
      expect({a = 1, b = 2}).to.match_table({a = 1})
    end)
    expect(ok).to.be_false()
  end)
end)

-- Test yields_values (coroutine matcher)
describe('yields_values matcher', function()
  it('should match coroutine yield sequence', function()
    expect(function()
      coroutine.yield(1)
      coroutine.yield(2)
      coroutine.yield(3)
    end).to.yield_values({1, 2, 3})
  end)

  it('should match empty yields', function()
    expect(function() end).to.yield_values({})
  end)

  it('should fail for wrong yield sequence', function()
    local ok = pcall(function()
      expect(function()
        coroutine.yield(1)
        coroutine.yield(2)
      end).to.yield_values({1, 2, 3})
    end)
    expect(ok).to.be_false()
  end)

  it('should fail for non-function', function()
    local ok = pcall(function()
      expect(42).to.yield_values({1})
    end)
    expect(ok).to.be_false()
  end)
end)

-- Test is_assertion_failure distinction
describe('assertion failure vs error distinction', function()
  it('should identify assertion failures', function()
    local ok, err = pcall(function()
      expect(1).to.be_equal_to(2)
    end)
    expect(ok).to.be_false()
    expect(test_api.is_assertion_failure(err)).to.be_true()
  end)

  it('should not identify regular errors as assertion failures', function()
    local ok, err = pcall(function()
      error('regular error')
    end)
    expect(ok).to.be_false()
    expect(test_api.is_assertion_failure(err)).to.be_false()
  end)
end)

-- Test before_all / after_all lifecycle
describe('before_all / after_all lifecycle', function()
  local counter = 0

  before_all(function()
    counter = counter + 100
  end)

  it('should run before_all once before first test', function()
    expect(counter).to.be_equal_to(100)
  end)

  it('should not run before_all again for second test', function()
    expect(counter).to.be_equal_to(100)
  end)
end)

-- Test before_each / after_each
describe('before_each / after_each', function()
  local value = 0

  before_each(function()
    value = value + 1
  end)

  after_each(function()
    value = 0
  end)

  it('first test should see value = 1', function()
    expect(value).to.be_equal_to(1)
  end)

  it('second test should also see value = 1 (reset by after_each)', function()
    expect(value).to.be_equal_to(1)
  end)
end)

-- Test additional matchers
describe('additional matchers', function()
  it('should support be_truthy', function()
    expect(true).to.be_truthy()
    expect(1).to.be_truthy()
    expect('hello').to.be_truthy()
  end)

  it('should support be_falsy', function()
    expect(false).to.be_falsy()
    expect(nil).to.be_falsy()
  end)

  it('should support be_nil', function()
    expect(nil).to.be_nil()
    expect(1).to_not.be_nil()
  end)

  it('should support be_a for type checking', function()
    expect('hello').to.be_a('string')
    expect(42).to.be_a('number')
    expect(true).to.be_a('boolean')
    expect({}).to.be_a('table')
  end)

  it('should support be_near for floats', function()
    expect(3.14159).to.be_near(3.14, 0.01)
  end)

  it('should support be_positive and be_negative', function()
    expect(5).to.be_positive()
    expect(-3).to.be_negative()
  end)

  it('should support be_between', function()
    expect(5).to.be_between(1, 10)
    expect(1).to.be_between(1, 10)
    expect(10).to.be_between(1, 10)
  end)

  it('should support contain for strings', function()
    expect('hello world').to.contain('world')
    expect('hello world').to_not.contain('xyz')
  end)

  it('should support match_pattern', function()
    expect('hello123').to.match_pattern('%a+%d+')
    expect('hello').to_not.match_pattern('^%d+$')
  end)

  it('should support be_empty', function()
    expect('').to.be_empty()
    expect({}).to.be_empty()
    expect('x').to_not.be_empty()
  end)

  it('should support have_size', function()
    expect({a = 1, b = 2}).to.have_size(2)
  end)

  it('should support contain_element for tables', function()
    expect({1, 2, 3}).to.contain_element(2)
    expect({1, 2, 3}).to_not.contain_element(5)
  end)

  it('should support have_property', function()
    expect({name = 'test', value = 42}).to.have_property('name', 'test')
    expect({name = 'test'}).to.have_property('name')
  end)

  it('should support respond_to', function()
    local obj = {greet = function() return 'hi' end}
    expect(obj).to.respond_to('greet')
    expect(obj).to_not.respond_to('missing')
  end)

  it('should support have_keys', function()
    expect({a = 1, b = 2, c = 3}).to.have_keys('a', 'b')
  end)

  it('should support be_even and be_odd', function()
    expect(4).to.be_even()
    expect(3).to.be_odd()
    expect(4).to_not.be_odd()
    expect(3).to_not.be_even()
  end)

  it('should support satisfy (all_of)', function()
    expect(5).to.satisfy(
      matchers_mod.greater_than(0),
      matchers_mod.less_than(10)
    )
  end)

  it('should support satisfy_any (any_of)', function()
    expect(5).to.satisfy_any(
      matchers_mod.equals(5),
      matchers_mod.equals(10)
    )
  end)

  it('should support none_of', function()
    expect(5).to.none_of(
      matchers_mod.equals(3),
      matchers_mod.equals(7)
    )
  end)

  it('should support be_nan', function()
    expect(0/0).to.be_nan()
    expect(42).to_not.be_nan()
  end)
end)

-- Test describe.each (parameterized suites)
describe.each({
  {1, 1, 2},
  {2, 3, 5},
  {10, 20, 30},
})('addition: %d + %d = %d', function(a, b, expected)
  it('should compute correct sum', function()
    expect(a + b).to.be_equal_to(expected)
  end)
end)

unit.run_unit_tests()
