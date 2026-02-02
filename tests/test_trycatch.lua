local llx = require 'llx'
local class = require 'llx.class' . class
local Exception = require 'llx.exceptions' . Exception
local Table = require 'llx.types.table' . Table
local try = require 'llx.flow_control.trycatch' . try
local catch = require 'llx.flow_control.catch' . catch
local unit = require 'llx.unit'
local types = require 'llx.types.matchers'

local FooException = class 'FooException' : extends(Exception) {}
local BarException = class 'BarException' : extends(Exception) {}
local BazException = class 'BazException' : extends(Exception) {}

local QuxException = class 'QuxException' : extends(FooException) {}

local Union = types.Union

_ENV = unit.create_test_env(_ENV)

describe('try', function()
  it('should catch first_exception', function()
    local result_branch
    local result_ex
    try {
      function()
        error(FooException('Hello'))
      end,
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
      catch(Union{BarException, BazException}, function(e)
        result_branch = 'BarOrQux'
        result_ex = e
      end),
      catch(Exception, function(e)
        result_branch = 'Exception'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
    expect(result_ex).to.be_of_type(FooException)
  end)

  it('should catch union_exception', function()
    local result_branch
    local result_ex
    try {
      function()
        error(BarException('Hello'))
      end,
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
      catch(Union{BarException, BazException}, function(e)
        result_branch = 'BarOrBaz'
        result_ex = e
      end),
      catch(Exception, function(e)
        result_branch = 'Exception'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('BarOrBaz')
    expect(result_ex).to.be_of_type(BarException)
  end)

  it('should catch fallback_exception', function()
    local result_branch
    local result_ex
    try {
      function()
        error(BarException('Hello'))
      end,
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
      catch(Exception, function(e)
        result_branch = 'Exception'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Exception')
    expect(result_ex).to.be_of_type(BarException)
  end)

  it('should catch inherited_exception', function()
    local result_branch
    local result_ex
    try {
      function()
        error(QuxException('Hello'))
      end,
      catch(QuxException, function(e)
        result_branch = 'Qux'
        result_ex = e
      end),
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Qux')
    expect(result_ex).to.be_of_type(QuxException)
  end)

  it('should catch inherited_exception_ordered_last', function()
    local result_branch
    local result_ex
    try {
      function()
        error(QuxException('Hello'))
      end,
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
      catch(QuxException, function(e)
        result_branch = 'Qux'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
    expect(result_ex).to.be_of_type(QuxException)
  end)

  it('should throw unhandled_exception', function()
    local result_branch
    local success, result_ex = pcall(function()
      try {
        function()
          error(BazException)
        end,
        catch(FooException, function(e)
          result_branch = 'Foo'
          result_ex = e
        end),
        catch(BarException, function(e)
          result_branch = 'Bar'
          result_ex = e
        end),
      }
    end)
    expect(success).to.be_false()
    expect(result_branch).to.be_nil()
    expect(result_ex).to.be_equal_to(BazException)
  end)

  it('should handle no_exception', function()
    local result_branch
    local result_ex
    try {
      function()
      end,
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
      catch(QuxException, function(e)
        result_branch = 'Qux'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_nil()
    expect(result_ex).to.be_nil()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
