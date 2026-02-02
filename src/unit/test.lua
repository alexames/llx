-- test.lua
-- Base test class and test decorator definition
--
-- @module unit.test

local llx = require 'llx'
local class = llx.class
local isinstance = llx.isinstance
local functional = require 'llx.functional'
local product = functional.product

local test_index = 0

--- Test decorator used to mark class methods as test cases.
-- Supports chained syntax: ['name' | test] = func
-- @param name Test name (string)
-- @return A marker object that supports __bor and __sub
local function test(name)
  test_index = test_index + 1
  local mt = {
    -- Allows: ['foo' | test] __sub 'bar' to extend name
    __sub = function(self, str)
      table.insert(self.name, str)
      return self
    end,
    -- Allows: ['foo' | test] | table to attach parameters
    __bor = function(self, t)
      table.insert(self.parameters, t)
      return self
    end,
  }
  local t = {index = test_index, name = {name}, parameter = {}, __istest = true}
  return setmetatable(t, mt)
end

--- Checks whether an object is a test decorator instance.
local function is_test(t)
  return isinstance(t, llx.Table) and t.__istest
end

--- Base class for test suites.
-- Users should subclass this when defining test classes.
local Test = class 'Test' {
  setup = llx.noop,
  teardown = llx.noop,

  __init = function(self)
    self._initialized = true
    self._tests = self:gather_tests()
    self._name = getmetatable(self).__name or '<name>'
  end,

  --- Returns gathered test metadata
  tests = function(self) return self._tests end,

  --- Returns the name of the test class
  name = function(self) return self._name end,

  --- Collects all test functions defined using `test` decorator
  gather_tests = function(self)
    local result = llx.Table()
    for key, testfunc in pairs(getmetatable(self)) do
      if is_test(key) then
        result:insert({index = key.index, name = key.name, func = testfunc})
      end
    end
    result:sort(function(a, b) return a.index < b.index end)
    return result
  end,

  --- Runs a single test with logging and setup/teardown
  run_test = function(self, printer, test, ...)
    printer.test_begin(self, test.name)
    self:setup()
    local successful, err = pcall(test.func, self, ...)
    self:teardown()
    printer.test_end(self, test.name, successful, err)
    return successful, err
  end,

  --- Runs all collected tests
  -- Handles parameterized tests (not yet implemented)
  run_tests = function(self, printer)
    if not self._initialized then
      error(string.format('a test suite was not initialized. '
                          .. 'Remember to call `self.Test.__init`'),
            3)
    end
    printer.class_preamble(self)
    local failure_count = 0
    for _, test in pairs(self._tests) do
      if test.arguments == nil or #test.arguments == 0 then
        local successful = self:run_test(printer, test)
        if not successful then
          failure_count = failure_count + 1
        end
      else
        for _, arguments in product(table.unpack(test.arguments)) do
          local successful = self:run_test(printer, test, table.unpack(arguments))
          if not successful then
            failure_count = failure_count + 1
          end
        end
      end
    end
    printer.class_conclusion(self, failure_count)
    return failure_count, #self._tests
  end,
}

return {
  test = test,
  Test = Test,
}
