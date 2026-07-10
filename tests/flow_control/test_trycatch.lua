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

describe('try with string catchers', function()
  it('should match the exception class name', function()
    local result_branch
    local result_ex
    try {
      function()
        error(FooException('Hello'))
      end,
      catch('BarException', function(e)
        result_branch = 'Bar'
        result_ex = e
      end),
      catch('FooException', function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
    expect(result_ex).to.be_of_type(FooException)
  end)

  it('should match a superclass name', function()
    local result_branch
    local result_ex
    try {
      function()
        error(QuxException('Hello'))
      end,
      catch('FooException', function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
    expect(result_ex).to.be_of_type(QuxException)
  end)

  it('should match a transitive superclass name', function()
    local result_branch
    try {
      function()
        error(QuxException('Hello'))
      end,
      catch('Exception', function(e)
        result_branch = 'Exception'
      end),
    }
    expect(result_branch).to.be_equal_to('Exception')
  end)

  it('should fall through an unrelated name to later catchers',
  function()
    local result_branch
    try {
      function()
        error(BarException('Hello'))
      end,
      catch('FooException', function(e)
        result_branch = 'Foo'
      end),
      catch(BarException, function(e)
        result_branch = 'Bar'
      end),
    }
    expect(result_branch).to.be_equal_to('Bar')
  end)

  it('should rethrow when no string catcher matches', function()
    local original = BazException('Hello')
    local success, result_ex = pcall(function()
      try {
        function()
          error(original)
        end,
        catch('FooException', function(e) end),
      }
    end)
    expect(success).to.be_false()
    expect(result_ex).to.be_equal_to(original)
  end)

  -- Dispatch goes through getclass, so string catchers also see
  -- non-exception thrown values by their type's __name.
  it('should match a raw string error by the String class name',
  function()
    local result_branch
    local result_ex
    try {
      function()
        error('a raw string error', 0)
      end,
      catch('FooException', function(e)
        result_branch = 'Foo'
      end),
      catch('String', function(e)
        result_branch = 'String'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('String')
    expect(result_ex).to.be_equal_to('a raw string error')
  end)
end)

describe('try with malformed catchers', function()
  -- Regression test for #92: a catch type that isinstance would
  -- reject must never replace the exception already unwinding with
  -- a secondary validation error. catch() rejects such values at
  -- construction, so a hand-built clause table stands in for one.
  it('should never mask the original exception', function()
    local original = FooException('the original exception')
    local success, result_ex = pcall(function()
      try {
        function()
          error(original)
        end,
        {exception=42, handler=function(e) end},
      }
    end)
    expect(success).to.be_false()
    expect(result_ex).to.be_equal_to(original)
  end)

  it('should never mask the original when __isinstance is falsy',
  function()
    local original = FooException('the original exception')
    local success, result_ex = pcall(function()
      try {
        function()
          error(original)
        end,
        {exception={__isinstance=false}, handler=function(e) end},
      }
    end)
    expect(success).to.be_false()
    expect(result_ex).to.be_equal_to(original)
  end)

  it('should never mask the original when __isinstance is not '
     .. 'callable', function()
    local original = FooException('the original exception')
    local success, result_ex = pcall(function()
      try {
        function()
          error(original)
        end,
        {exception={__isinstance=42}, handler=function(e) end},
      }
    end)
    expect(success).to.be_false()
    expect(result_ex).to.be_equal_to(original)
  end)

  it('should skip a malformed catcher and reach a valid one',
  function()
    local result_branch
    local result_ex
    try {
      function()
        error(FooException('Hello'))
      end,
      {exception={}, handler=function(e) end},
      catch(FooException, function(e)
        result_branch = 'Foo'
        result_ex = e
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
    expect(result_ex).to.be_of_type(FooException)
  end)

  it('should skip a non-table catch clause entry', function()
    local result_branch
    try {
      function()
        error(FooException('Hello'))
      end,
      'not a catch clause',
      catch(FooException, function(e)
        result_branch = 'Foo'
      end),
    }
    expect(result_branch).to.be_equal_to('Foo')
  end)
end)

describe('llx.flow_control aggregator', function()
  it('should expose try and catch directly', function()
    expect(type(llx.flow_control.try)).to.be_equal_to('function')
    expect(type(llx.flow_control.catch)).to.be_equal_to('function')
  end)

  it('should let callers use try/catch without per-file requires', function()
    local exceptions = llx.exceptions
    local caught = nil
    llx.flow_control.try {
      function() error(exceptions.ValueException('aggregator works')) end;
      llx.flow_control.catch(exceptions.ValueException, function(e)
        caught = e
      end);
    }
    expect(caught).to_not.be_nil()
    expect(caught.what).to.be_equal_to('aggregator works')
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
