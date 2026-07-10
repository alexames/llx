local unit = require 'llx.unit'
local llx = require 'llx'
local catch = require 'llx.flow_control.catch' . catch
local exceptions = require 'llx.exceptions'
local isinstance = require 'llx.isinstance' . isinstance
local types = require 'llx.types.matchers'

_ENV = unit.create_test_env(_ENV)

describe('catch', function()
  it('should return a table with exception and handler fields', function()
    local exception_type = 'SomeException'
    local handler_fn = function() end
    local result = catch(exception_type, handler_fn)
    expect(result.exception).to.be_equal_to(exception_type)
    expect(result.handler).to.be_equal_to(handler_fn)
  end)

  it('should store a string exception type', function()
    local result = catch('TypeError', function() end)
    expect(result.exception).to.be_equal_to('TypeError')
  end)

  it('should store the handler function', function()
    local called = false
    local handler = function() called = true end
    local result = catch('Error', handler)
    result.handler()
    expect(called).to.be_true()
  end)

  it('should handle nil handler', function()
    local result = catch('Error', nil)
    expect(result.handler).to.be_nil()
  end)

  it('should return a plain table without metatable', function()
    local result = catch('Error', function() end)
    expect(getmetatable(result)).to.be_nil()
  end)

  it('should return distinct tables for each call', function()
    local handler = function() end
    local result1 = catch('Error1', handler)
    local result2 = catch('Error2', handler)
    expect(result1).to_not.be_equal_to(result2)
    expect(result1.exception).to.be_equal_to('Error1')
    expect(result2.exception).to.be_equal_to('Error2')
  end)

  it('should work with class-based exception types', function()
    local class = require 'llx.class' . class
    local Exception = exceptions.Exception
    local MyException = class 'MyException' : extends(Exception) {}
    local handler = function(e) return e end
    local result = catch(MyException, handler)
    expect(result.exception).to.be_equal_to(MyException)
    expect(result.handler).to.be_equal_to(handler)
  end)

  it('should work with type matchers', function()
    local matcher =
        types.Union{exceptions.TypeError, exceptions.IndexError}
    local result = catch(matcher, function() end)
    expect(result.exception).to.be_equal_to(matcher)
  end)

  it('should reject a nil exception type at construction', function()
    local success, err = pcall(catch, nil, function() end)
    expect(success).to.be_false()
    expect(isinstance(err, exceptions.InvalidArgumentException))
        .to.be_true()
  end)

  it('should reject a number exception type at construction',
  function()
    local success, err = pcall(catch, 42, function() end)
    expect(success).to.be_false()
    expect(isinstance(err, exceptions.InvalidArgumentException))
        .to.be_true()
  end)

  it('should reject a plain table exception type at construction',
  function()
    local success, err =
        pcall(catch, {name = 'CustomException'}, function() end)
    expect(success).to.be_false()
    expect(isinstance(err, exceptions.InvalidArgumentException))
        .to.be_true()
  end)

  it('should reject a falsy __isinstance at construction', function()
    local success, err =
        pcall(catch, {__isinstance = false}, function() end)
    expect(success).to.be_false()
    expect(isinstance(err, exceptions.InvalidArgumentException))
        .to.be_true()
  end)

  it('should reject a non-callable __isinstance at construction',
  function()
    local success, err =
        pcall(catch, {__isinstance = 42}, function() end)
    expect(success).to.be_false()
    expect(isinstance(err, exceptions.InvalidArgumentException))
        .to.be_true()
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
