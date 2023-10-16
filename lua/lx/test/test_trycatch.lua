require 'lx/unit'
require 'lx/trycatch'
require 'ext/table'
local class = require 'lx/class'
local types = require 'types/basic_types'
local Exception = require 'lx/exception'

local FooException = class 'FooException' : extends(Exception) {}
local BarException = class 'BarException' : extends(Exception) {}
local BazException = class 'BazException' : extends(Exception) {}

local QuxException = class 'QuxException' : extends(FooException) {}

local Union = types.Union

test_class 'try' {
  [test('first_exception')] = function()
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
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,

  [test('union_exception')] = function()
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
    EXPECT_EQ(result_branch, 'BarOrBaz')
    EXPECT_THAT(result_ex, IsOfType(BarException))
  end,

  [test('fallback_exception')] = function()
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
    EXPECT_EQ(result_branch, 'Exception')
    EXPECT_THAT(result_ex, IsOfType(BarException))
  end,

  [test('inherited_exception')] = function()
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
    EXPECT_EQ(result_branch, 'Qux')
    EXPECT_THAT(result_ex, IsOfType(QuxException))
  end,

  [test('inherited_exception_ordered_last')] = function()
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
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(QuxException))
  end,

  [test('unhandled_exception')] = function()
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
    EXPECT_FALSE(success)
    EXPECT_EQ(result_branch, nil)
    EXPECT_EQ(result_ex, BazException)
  end,

  [test('no_exception')] = function()
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
    EXPECT_EQ(result_branch, nil)
    EXPECT_EQ(result_ex, nil)
  end,
}

