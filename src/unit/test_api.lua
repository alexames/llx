-- test_api.lua
-- describe/it/expect API for unit testing
--
-- @module llx.unit.test_api

local llx = require 'llx'
local test = require 'llx.unit.test'
local matchers = require 'llx.unit.matchers'
local mock_module = require 'llx.unit.mock'
local truthy, falsey = require 'llx.truthy' {'truthy', 'falsey'}
local functional = require 'llx.functional'

local class = llx.class
local Mock = mock_module.Mock
local product = functional.product

-- Sentinel type for assertion failures (distinct from unexpected errors)
local ASSERTION_FAILURE = {}

-- Helper function to evaluate a matcher and throw an error if it doesn't pass
local function evaluate_matcher(actual, matcher, level)
  level = level or 3
  local result = matcher(actual)
  if type(result) ~= 'table' or result.pass == nil then
    error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', level)
  end
  if not result.pass then
    local msg = 'expected ' .. result.actual .. '\nto ' .. result.positive_message .. '\n  ' .. result.expected
    error(setmetatable({message = msg, type = ASSERTION_FAILURE}, {
      __tostring = function(self) return self.message end
    }), level)
  end
end

--- Checks if an error is an assertion failure (as opposed to an unexpected error).
local function is_assertion_failure(err)
  return type(err) == 'table' and err.type == ASSERTION_FAILURE
end

-- Context stack for nested describe blocks
local describe_context_stack = {}

-- Global test suites registered via describe
local test_suites = llx.Table{}

-- Global lifecycle hooks
local global_before_all_hooks = {}
local global_after_all_hooks = {}

--- Public table for registering custom matchers.
-- Users can add their own matchers by assigning to this table.
-- Matchers should be functions that take arguments and return a matcher function.
-- For example: matchers.be_equal_to = matchers.equals
local custom_matchers = {}

--- Registers a custom matcher with validation.
-- The matcher function should accept arguments and return a function that accepts
-- the actual value and returns a result table with pass, actual, positive_message,
-- negative_message, and expected fields.
-- @param name The name of the matcher (string)
-- @param matcher_fn The matcher creator function
local function expect_extend(name, matcher_fn)
  if type(name) ~= 'string' then
    error('expect.extend: name must be a string, got ' .. type(name), 2)
  end
  if type(matcher_fn) ~= 'function' then
    error('expect.extend: matcher must be a function, got ' .. type(matcher_fn), 2)
  end
  -- Validate the matcher by calling it with a dummy value
  local ok, err = pcall(function()
    local matcher = matcher_fn()
    if type(matcher) ~= 'function' then
      error('matcher creator must return a function, got ' .. type(matcher))
    end
    local result = matcher(nil)
    if type(result) ~= 'table' then
      error('matcher must return a table, got ' .. type(result))
    end
    if result.pass == nil then
      error('matcher result must have a "pass" field')
    end
    local required_fields = {'actual', 'positive_message', 'negative_message', 'expected'}
    for _, field in ipairs(required_fields) do
      if result[field] == nil then
        error('matcher result missing required field: ' .. field)
      end
    end
  end)
  if not ok then
    error('expect.extend: invalid matcher "' .. name .. '": ' .. tostring(err), 2)
  end
  custom_matchers[name] = matcher_fn
end

--- Creates an expect object with matcher methods
-- @param actual The actual value to test
-- @return An object with to and to_not properties
local function expect(actual)
  local expect_obj = {
    _actual = actual,
  }

  -- Helper to create a matcher method from a matcher entry
  local function create_matcher_method(matcher_creator, negated)
    if type(matcher_creator) ~= 'function' then
      return nil
    end
    
      return function(...)
      local matcher = matcher_creator(...)
      if negated then
        matcher = matchers.negate(matcher)
      end
      evaluate_matcher(expect_obj._actual, matcher, 3)
    end
  end

  -- Create proxies that dynamically look up matchers from custom_matchers
  local to_proxy = {}
  setmetatable(to_proxy, {
    __index = function(_, key)
      -- Handle special matchers
      if key == 'throw' then
        return function(expected)
          local level = 3
          if type(expect_obj._actual) ~= 'function' then
            error('throw() expects a function, got ' .. type(expect_obj._actual), level)
          end
          
          local successful, exception = pcall(expect_obj._actual)

          if successful then
            error('expected function to raise error', level)
          end
          -- Now we know it threw, match the message if expected
          if expected then
            local exception_msg = exception
            if type(expected) == 'string' and type(exception) == 'string' then
              local path_colon = exception:find(':', 1, true)
              local line_colon = exception:find(':', path_colon + 1, true)
              if line_colon then
                exception_msg = exception:sub(line_colon + 2)
              end
            end
            evaluate_matcher(exception_msg, matchers.equals(expected), level + 1)
          end
        end
      elseif key == 'match' then
        return function(matcher_func)
          evaluate_matcher(expect_obj._actual, matcher_func, 3)
        end
      elseif key == 'satisfy' then
        return function(...)
          evaluate_matcher(expect_obj._actual, matchers.all_of(...), 3)
        end
      elseif key == 'satisfy_any' then
        return function(...)
          evaluate_matcher(expect_obj._actual, matchers.any_of(...), 3)
        end
      else
        -- Look up in custom_matchers
        local matcher_creator = custom_matchers[key]
        if matcher_creator then
          return create_matcher_method(matcher_creator, false)
        end
      end
      return nil
    end
  })

  local to_not_proxy = {}
  setmetatable(to_not_proxy, {
    __index = function(_, key)
      -- Handle special matchers
      if key == 'throw' then
        return function(expected)
          local level = 3
          if type(expect_obj._actual) ~= 'function' then
            error('throw() expects a function, got ' .. type(expect_obj._actual), level)
          end
          local successful, exception = pcall(expect_obj._actual)
          if not successful then
            error('expected function not to raise error, but got: ' .. tostring(exception), level)
          end
        end
      elseif key == 'match' then
        return function(matcher_func)
          evaluate_matcher(expect_obj._actual, matchers.negate(matcher_func), 3)
        end
      elseif key == 'satisfy' then
        return function(...)
          evaluate_matcher(expect_obj._actual, matchers.negate(matchers.all_of(...)), 3)
        end
      elseif key == 'satisfy_any' then
        return function(...)
          evaluate_matcher(expect_obj._actual, matchers.negate(matchers.any_of(...)), 3)
        end
      else
        -- Look up in custom_matchers
        local matcher_creator = custom_matchers[key]
        if matcher_creator then
          return create_matcher_method(matcher_creator, true)
        end
      end
      return nil
    end
  })

  expect_obj.to = to_proxy
  expect_obj.to_not = to_not_proxy

  return expect_obj
end

-- Register all built-in matchers (all in snake_case)
custom_matchers.be_equal_to = matchers.equals
custom_matchers.be_greater_than = matchers.greater_than
custom_matchers.be_greater_than_or_equal = matchers.greater_than_or_equal
custom_matchers.be_less_than = matchers.less_than
custom_matchers.be_less_than_or_equal = matchers.less_than_or_equal
custom_matchers.contain = matchers.contains
custom_matchers.match_pattern = matchers.matches
custom_matchers.start_with = matchers.starts_with
custom_matchers.end_with = matchers.ends_with
custom_matchers.have_length = matchers.has_length
custom_matchers.be_empty = function() return matchers.is_empty() end
custom_matchers.have_size = matchers.has_size
custom_matchers.contain_element = matchers.contains_element
custom_matchers.be_nil = function() return matchers.equals(nil) end
custom_matchers.be_truthy = function()
  return function(actual)
    return {
      pass = truthy(actual),
      actual = tostring(actual),
      positive_message = 'be truthy',
      negative_message = 'be not truthy',
      expected = 'truthy value'
    }
  end
end
custom_matchers.be_falsy = function()
  return function(actual)
    return {
      pass = falsey(actual),
      actual = tostring(actual),
      positive_message = 'be falsy',
      negative_message = 'be not falsy',
      expected = 'falsy value'
    }
  end
end
custom_matchers.be_true = function()
  return function(actual)
    return {
      pass = actual == true,
      actual = tostring(actual),
      positive_message = 'be true',
      negative_message = 'be not true',
      expected = 'true'
    }
  end
end
custom_matchers.be_false = function()
  return function(actual)
    return {
      pass = actual == false,
      actual = tostring(actual),
      positive_message = 'be false',
      negative_message = 'be not false',
      expected = 'false'
    }
  end
end
custom_matchers.be_near = matchers.near
custom_matchers.be_positive = function() return matchers.is_positive() end
custom_matchers.be_negative = function() return matchers.is_negative() end
custom_matchers.be_between = matchers.is_between
custom_matchers.be_nan = function() return matchers.is_nan() end
custom_matchers.be_of_type = matchers.is_of_type

-- New matchers
custom_matchers.be_instance_of = matchers.is_instance_of
custom_matchers.match_table = matchers.match_table
custom_matchers.have_property = matchers.have_property
custom_matchers.respond_to = matchers.respond_to
custom_matchers.be_a = matchers.be_a
custom_matchers.have_keys = matchers.have_keys
custom_matchers.be_even = matchers.be_even
custom_matchers.be_odd = matchers.be_odd
custom_matchers.none_of = matchers.none_of

-- Helper to check if value is a Mock instance
local function is_mock(value)
  return type(value) == 'table' and getmetatable(value) == Mock
end

-- Helper to pack arguments preserving nil values and count
local function pack_args(...)
  return {n = select('#', ...), ...}
end

-- Helper to format arguments for error messages
-- Handles matchers, nil values, and non-string types
local function format_args(args)
  local formatted = {}
  for i = 1, (args.n or #args) do
    local arg = args[i]
    if type(arg) == 'function' then
      -- This is likely a matcher function
      table.insert(formatted, '<matcher>')
    elseif arg == nil then
      table.insert(formatted, 'nil')
    else
      table.insert(formatted, tostring(arg))
    end
  end
  return table.concat(formatted, ', ')
end

-- Helper to match arguments using matchers
-- Handles nil values explicitly and supports matcher functions
local function match_args(actual_args, expected_args)
  -- Check length first (use .n if available from pack_args)
  local actual_len = actual_args.n or #actual_args
  local expected_len = expected_args.n or #expected_args
  if actual_len ~= expected_len then
    return false
  end

  -- Use numeric for loop to handle nil values correctly
  for i = 1, expected_len do
    local expected = expected_args[i]
    local actual = actual_args[i]

    -- Handle nil values explicitly
    if expected == nil and actual ~= nil then
      return false
    elseif expected ~= nil and actual == nil then
      return false
    elseif expected == nil and actual == nil then
      -- Both nil, continue to next argument
    -- If expected is a matcher function, use it
    elseif type(expected) == 'function' then
      local result = expected(actual)
      if type(result) ~= 'table' or result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      if not result.pass then
        return false
      end
    -- Otherwise do direct equality check
    elseif actual ~= expected then
      return false
    end
  end

  return true
end

-- Mock matchers (removed 'to' prefix, using snake_case)
custom_matchers.have_been_called = function()
  return function(actual)
    if not is_mock(actual) then
      error('have_been_called() expects a Mock, got ' .. type(actual), 3)
    end
    local count = actual:mock_get_call_count()
    return {
      pass = count > 0,
      actual = tostring(count) .. ' call(s)',
      positive_message = 'have been called',
      negative_message = 'not have been called',
      expected = 'at least 1 call'
    }
  end
end

custom_matchers.have_been_called_times = function(expected)
  return function(actual)
    if not is_mock(actual) then
      error('have_been_called_times() expects a Mock, got ' .. type(actual), 3)
    end
    local count = actual:mock_get_call_count()
    return {
      pass = count == expected,
      actual = tostring(count) .. ' call(s)',
      positive_message = 'have been called',
      negative_message = 'not have been called',
      expected = tostring(expected) .. ' call(s)'
    }
  end
end

custom_matchers.have_been_called_with = function(...)
  local expected_args = pack_args(...)
  return function(actual)
    if not is_mock(actual) then
      error('have_been_called_with() expects a Mock, got ' .. type(actual), 3)
    end
    local calls = actual:mock_get_calls()
    for _, call in ipairs(calls) do
      if match_args(call.args, expected_args) then
        return {
          pass = true,
          actual = 'mock was called',
          positive_message = 'have been called with',
          negative_message = 'not have been called with',
          expected = 'arguments matching the call'
        }
      end
    end
    return {
      pass = false,
      actual = 'mock was not called with matching arguments',
      positive_message = 'have been called with',
      negative_message = 'not have been called with',
      expected = 'arguments matching: ' .. format_args(expected_args)
    }
  end
end

custom_matchers.have_been_last_called_with = function(...)
  local expected_args = pack_args(...)
  return function(actual)
    if not is_mock(actual) then
      error('have_been_last_called_with() expects a Mock, got ' .. type(actual), 3)
    end
    local last_call = actual:mock_get_last_call()
    if not last_call then
      return {
        pass = false,
        actual = 'mock was never called',
        positive_message = 'have been last called with',
        negative_message = 'not have been last called with',
        expected = 'arguments matching: ' .. format_args(expected_args)
      }
    end
    local matched = match_args(last_call.args, expected_args)
    return {
      pass = matched,
      actual = 'last call was with: ' .. format_args(last_call.args),
      positive_message = 'have been last called with',
      negative_message = 'not have been last called with',
      expected = 'arguments matching: ' .. format_args(expected_args)
    }
  end
end

custom_matchers.have_been_nth_called_with = function(n, ...)
  -- Validate n is a positive integer
  if type(n) ~= 'number' or n < 1 or math.floor(n) ~= n then
    error('have_been_nth_called_with() expects a positive integer as first argument, got ' .. tostring(n), 3)
  end
  local expected_args = pack_args(...)
  return function(actual)
    if not is_mock(actual) then
      error('have_been_nth_called_with() expects a Mock, got ' .. type(actual), 3)
    end
    local call = actual:mock_get_call(n)
    if not call then
      return {
        pass = false,
        actual = 'mock was called ' .. tostring(actual:mock_get_call_count()) .. ' time(s)',
        positive_message = 'have been nth called with',
        negative_message = 'not have been nth called with',
        expected = 'call #' .. tostring(n) .. ' with arguments matching: ' .. format_args(expected_args)
      }
    end
    local matched = match_args(call.args, expected_args)
    return {
      pass = matched,
      actual = 'call #' .. tostring(n) .. ' was with: ' .. format_args(call.args),
      positive_message = 'have been nth called with',
      negative_message = 'not have been nth called with',
      expected = 'call #' .. tostring(n) .. ' with arguments matching: ' .. format_args(expected_args)
    }
  end
end

custom_matchers.have_returned = function()
  return function(actual)
    if not is_mock(actual) then
      error('have_returned() expects a Mock, got ' .. type(actual), 3)
    end
    local calls = actual:mock_get_calls()
    local has_returned = false
    for _, call in ipairs(calls) do
      if call.return_value ~= nil then
        has_returned = true
        break
      end
    end
    return {
      pass = has_returned,
      actual = tostring(actual:mock_get_call_count()) .. ' call(s)',
      positive_message = 'have returned',
      negative_message = 'not have returned',
      expected = 'at least one call with a return value'
    }
  end
end

custom_matchers.have_returned_with = function(expected_value)
  return function(actual)
    if not is_mock(actual) then
      error('have_returned_with() expects a Mock, got ' .. type(actual), 3)
    end
    local calls = actual:mock_get_calls()
    for _, call in ipairs(calls) do
      if call.return_value == expected_value then
        return {
          pass = true,
          actual = 'mock returned matching value',
          positive_message = 'have returned with',
          negative_message = 'not have returned with',
          expected = tostring(expected_value)
        }
      end
    end
    return {
      pass = false,
      actual = 'mock never returned matching value',
      positive_message = 'have returned with',
      negative_message = 'not have returned with',
      expected = tostring(expected_value)
    }
  end
end

custom_matchers.have_last_returned_with = function(expected_value)
  return function(actual)
    if not is_mock(actual) then
      error('have_last_returned_with() expects a Mock, got ' .. type(actual), 3)
    end
    local last_call = actual:mock_get_last_call()
    if not last_call then
      return {
        pass = false,
        actual = 'mock was never called',
        positive_message = 'have last returned with',
        negative_message = 'not have last returned with',
        expected = tostring(expected_value)
      }
    end
    return {
      pass = last_call.return_value == expected_value,
      actual = 'last return value: ' .. tostring(last_call.return_value),
      positive_message = 'have last returned with',
      negative_message = 'not have last returned with',
      expected = tostring(expected_value)
    }
  end
end

custom_matchers.have_nth_returned_with = function(n, expected_value)
  if type(n) ~= 'number' or n < 1 or math.floor(n) ~= n then
    error('have_nth_returned_with() expects a positive integer as first argument, got ' .. tostring(n), 3)
  end
  return function(actual)
    if not is_mock(actual) then
      error('have_nth_returned_with() expects a Mock, got ' .. type(actual), 3)
    end
    local call = actual:mock_get_call(n)
    if not call then
      return {
        pass = false,
        actual = 'mock was called ' .. tostring(actual:mock_get_call_count()) .. ' time(s)',
        positive_message = 'have nth returned with',
        negative_message = 'not have nth returned with',
        expected = 'call #' .. tostring(n) .. ' returning ' .. tostring(expected_value)
      }
    end
    return {
      pass = call.return_value == expected_value,
      actual = 'call #' .. tostring(n) .. ' returned: ' .. tostring(call.return_value),
      positive_message = 'have nth returned with',
      negative_message = 'not have nth returned with',
      expected = 'call #' .. tostring(n) .. ' returning ' .. tostring(expected_value)
    }
  end
end

-- Special matchers that need custom handling (not registered in custom_matchers)
-- These are handled directly in the proxy __index functions

--- Test class for describe/it style tests
local TestSuite = class 'TestSuite':extends(test.Test) {
  __init = function(self, suite_name, tests, nested_suite_classes, name_path)
    -- Set test data before calling base __init, which calls gather_tests()
    self._name = suite_name
    self._name_path = name_path or {suite_name}
    self._tests_data = tests or {}
    self._nested_suite_classes = nested_suite_classes or {}
    self._before_all_run = false
    -- Initialize nested suites before base __init calls gather_tests()
    self._nested_suites = {}
    for _, nested_class in ipairs(self._nested_suite_classes) do
      local nested_instance = nested_class(
        nested_class.__name,
        nested_class.__tests_data,
        nested_class.__nested_suites or {},
        nested_class.__name_path or {nested_class.__name}
      )
      table.insert(self._nested_suites, nested_instance)
    end
    -- Now call base __init which will call our overridden gather_tests()
    test.Test.__init(self)
  end,

  gather_tests = function(self)
    local result = llx.Table()
    local test_index = 1
    local has_only = false

    -- First pass: check if any tests have 'only' flag
    for _, test_case in ipairs(self._tests_data) do
      if test_case.only then
        has_only = true
        break
      end
    end

    -- Add direct tests from this suite
    for i, test_case in ipairs(self._tests_data) do
      -- Skip tests marked as skip (but still add them for reporting)
      if test_case.skip then
        result:insert({
          index = test_index,
          name = test_case.name_path or {test_case.name},
          func = test_case.func,
          suite = self,
          skip = true,
          only = test_case.only,
          todo = test_case.todo,
        })
        test_index = test_index + 1
      -- If there are 'only' tests, only include those
      elseif has_only and not test_case.only then
        result:insert({
          index = test_index,
          name = test_case.name_path or {test_case.name},
          func = test_case.func,
          suite = self,
          skip = true,
          only = test_case.only,
          todo = test_case.todo,
        })
        test_index = test_index + 1
      else
        result:insert({
          index = test_index,
          name = test_case.name_path or {test_case.name},
          func = test_case.func,
          suite = self,
          skip = test_case.skip,
          only = test_case.only,
          todo = test_case.todo,
        })
        test_index = test_index + 1
      end
    end

    -- Recursively add tests from nested suites
    for _, nested_suite in ipairs(self._nested_suites) do
      local nested_tests = nested_suite:gather_tests()
      for _, nested_test in ipairs(nested_tests) do
        result:insert({
          index = test_index,
          name = nested_test.name,
          func = nested_test.func,
          suite = nested_test.suite or nested_suite,  -- Track nested suite
          skip = nested_test.skip,
          only = nested_test.only,
          todo = nested_test.todo,
        })
        test_index = test_index + 1
      end
    end

    return result
  end,
  
  -- Override name() to return the full path
  name = function(self)
    return table.concat(self._name_path, ' > ')
  end,
  
  -- Override run_tests to add beforeAll/afterAll support
  run_tests = function(self, printer)
    if not self._initialized then
      error(string.format('a test suite was not initialized. '
                          .. 'Remember to call `self.Test.__init`'),
            3)
    end

    -- Track which suites had before_all attempted (for cleanup)
    local suites_before_all_attempted = {}

    -- Run beforeAll hook once before all tests
    local before_all = getmetatable(self).__before_all
    if before_all and before_all ~= llx.noop and not self._before_all_run then
      suites_before_all_attempted[self] = true
      local success, err = pcall(before_all)
      if not success then
        printer.class_preamble(self)
        printer.class_conclusion(self, #self._tests) -- Mark all as failed
        -- Still run after_all even if before_all failed
        local after_all = getmetatable(self).__after_all
        if after_all and after_all ~= llx.noop then
          pcall(after_all)
        end
        return #self._tests, #self._tests
      end
      self._before_all_run = true
    end

    printer.class_preamble(self)
    local failure_count = 0
    local current_suite = nil
    local suite_before_all_run = {}
    local suite_before_all_failed = {}

    for _, test in pairs(self._tests) do
      -- Run beforeAll for the test's suite if it's different from current
      local test_suite = test.suite or self
      if test_suite ~= current_suite then
        current_suite = test_suite
        if test_suite ~= self then
          -- This is a nested suite test, run its beforeAll if not already run
          if not suite_before_all_run[test_suite] then
            local nested_before_all = getmetatable(test_suite).__before_all
            if nested_before_all and nested_before_all ~= llx.noop then
              suites_before_all_attempted[test_suite] = true
              local nested_success, nested_err = pcall(nested_before_all)
              suite_before_all_run[test_suite] = true
              if not nested_success then
                suite_before_all_failed[test_suite] = nested_err
              end
            end
          end
        end
      end

      -- Skip tests from suites whose before_all failed
      if suite_before_all_failed[test_suite] then
        printer.test_begin(self, test.name)
        printer.test_end(self, test.name, false,
          "before_all failed: " .. tostring(suite_before_all_failed[test_suite]))
        failure_count = failure_count + 1
      elseif test.todo then
        printer.test_todo(self, test.name)
      elseif test.skip then
        printer.test_skip(self, test.name)
      elseif test.arguments == nil or #test.arguments == 0 then
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

    -- Run afterAll hooks for all suites where before_all was attempted
    local suites_to_cleanup = {[self] = true}
    for suite, _ in pairs(suites_before_all_attempted) do
      suites_to_cleanup[suite] = true
    end
    for suite, _ in pairs(suite_before_all_run) do
      suites_to_cleanup[suite] = true
    end
    for suite, _ in pairs(suites_to_cleanup) do
      local after_all = getmetatable(suite).__after_all
      if after_all and after_all ~= llx.noop then
        pcall(after_all)
      end
    end

    printer.class_conclusion(self, failure_count)

    return failure_count, #self._tests
  end,
}

--- Registers a test case within the current describe context
-- @param name Test name
-- @param func Test function
-- @param skip Optional flag to skip this test
-- @param only Optional flag to run only this test
local function it_impl(name, func, skip, only, todo)
  local context = describe_context_stack[#describe_context_stack]
  if not context then
    error('it() must be called within a describe() block', 2)
  end

  -- Build the full name path from the context hierarchy
  local name_path = {}
  for _, ctx in ipairs(describe_context_stack) do
    table.insert(name_path, ctx.name)
  end
  table.insert(name_path, name)

  table.insert(context.tests, {
    name = name,
    name_path = name_path,
    func = func,
    skip = skip,
    only = only,
    todo = todo,
  })
end

-- Create it as a callable table with skip/only methods
local it = setmetatable({
  skip = function(name, func)
    return it_impl(name, func, true, false)
  end,
  only = function(name, func)
    return it_impl(name, func, false, true)
  end,
  todo = function(name)
    return it_impl(name, nil, false, false, true)
  end
}, {
  __call = function(_, name, func, skip, only)
    return it_impl(name, func, skip, only)
  end
})

-- Alias for it
local test = setmetatable({
  skip = it.skip,
  only = it.only
}, {
  __call = function(_, name, func, skip, only)
    return it_impl(name, func, skip, only)
  end
})

--- Creates a test suite (describe block)
-- @param name Suite name
-- @param func Function that contains it() calls
-- @param skip Optional flag to skip this suite
-- @param only Optional flag to run only this suite
local function describe_impl(name, func, skip, only)
  local parent_context = describe_context_stack[#describe_context_stack]

  -- Build the name path from the context hierarchy
  local name_path = {}
  for _, ctx in ipairs(describe_context_stack) do
    table.insert(name_path, ctx.name)
  end
  table.insert(name_path, name)

  local context = {
    name = name,
    name_path = name_path,
    tests = {},
    nested_suites = {},
    setup = llx.noop,
    teardown = llx.noop,
    before_all = llx.noop,
    after_all = llx.noop,
    skip = skip,
    only = only,
    parent_context = parent_context,
  }

  table.insert(describe_context_stack, context)

  -- Execute the describe block to collect tests and nested describes
  local success, err = pcall(func)

  table.remove(describe_context_stack)

  if not success then
    error('Error in describe block "' .. name .. '": ' .. tostring(err), 2)
  end

  -- Create a test class for this suite
  local suite_class = class(table.concat(name_path, '_')):extends(TestSuite) {
    __init = function(self, suite_name, tests, nested_suites, name_path)
      TestSuite.__init(self, suite_name, tests, nested_suites, name_path)
    end,
  }

  -- Store the test data for later instantiation
  suite_class.__tests_data = context.tests
  suite_class.__nested_suites = context.nested_suites
  suite_class.__name_path = context.name_path
  suite_class.__setup = context.setup
  suite_class.__teardown = context.teardown
  suite_class.__before_all = context.before_all
  suite_class.__after_all = context.after_all
  suite_class.__skip = context.skip
  suite_class.__only = context.only

  -- Compose setup/teardown with parent hooks for inheritance
  -- before_each: run ancestor hooks first (outermost to innermost)
  -- after_each: run descendant hooks first (innermost to outermost)
  local function collect_setups(ctx)
    local setups = {}
    while ctx do
      if ctx.setup ~= llx.noop then
        table.insert(setups, 1, ctx.setup) -- prepend (outermost first)
      end
      ctx = ctx.parent_context
    end
    return setups
  end

  local function collect_teardowns(ctx)
    local teardowns = {}
    while ctx do
      if ctx.teardown ~= llx.noop then
        table.insert(teardowns, ctx.teardown) -- append (innermost first)
      end
      ctx = ctx.parent_context
    end
    return teardowns
  end

  local setups = collect_setups(context)
  local teardowns = collect_teardowns(context)

  if #setups > 0 then
    suite_class.setup = function(self)
      for _, setup_fn in ipairs(setups) do
        setup_fn(self)
      end
    end
  end
  if #teardowns > 0 then
    suite_class.teardown = function(self)
      for _, teardown_fn in ipairs(teardowns) do
        teardown_fn(self)
      end
    end
  end

  -- If there's a parent context, add this as a nested suite
  -- Otherwise, add it as a top-level suite
  if parent_context then
    table.insert(parent_context.nested_suites, suite_class)
  else
    test_suites:insert(suite_class)
  end
end

-- Create describe as a callable table with skip/only methods
local describe = setmetatable({
  skip = function(name, func)
    return describe_impl(name, func, true, false)
  end,
  only = function(name, func)
    return describe_impl(name, func, false, true)
  end
}, {
  __call = function(_, name, func, skip, only)
    return describe_impl(name, func, skip, only)
  end
})

--- Setup function for the current describe block
-- @param func Setup function
local function before_each(func)
  local context = describe_context_stack[#describe_context_stack]
  if not context then
    error('before_each() must be called within a describe() block', 2)
  end
  context.setup = func
end

--- Teardown function for the current describe block
-- @param func Teardown function
local function after_each(func)
  local context = describe_context_stack[#describe_context_stack]
  if not context then
    error('after_each() must be called within a describe() block', 2)
  end
  context.teardown = func
end

--- Setup function that runs once before all tests in the current describe block
-- @param func Setup function
local function before_all(func)
  local context = describe_context_stack[#describe_context_stack]
  if not context then
    error('before_all() must be called within a describe() block', 2)
  end
  context.before_all = func
end

--- Teardown function that runs once after all tests in the current describe block
-- @param func Teardown function
local function after_all(func)
  local context = describe_context_stack[#describe_context_stack]
  if not context then
    error('after_all() must be called within a describe() block', 2)
  end
  context.after_all = func
end

--- Global setup function that runs once before all test suites
-- @param func Setup function
local function global_before_all(func)
  if type(func) ~= 'function' then
    error('global_before_all() expects a function, got ' .. type(func), 2)
  end
  table.insert(global_before_all_hooks, func)
end

--- Global teardown function that runs once after all test suites
-- @param func Teardown function
local function global_after_all(func)
  if type(func) ~= 'function' then
    error('global_after_all() expects a function, got ' .. type(func), 2)
  end
  table.insert(global_after_all_hooks, func)
end

--- Runs all tests registered via describe/it
-- @param[opt] filter A string to match against test suite names
-- @param[opt] logger An optional logger object to capture output
local function run_tests(filter, logger)
  local test_logger = require 'llx.unit.test_logger'
  logger = logger or test_logger.HierarchicalLogger()
  local total_failure_count = 0
  local total_test_count = 0

  -- Check if any suites have 'only' flag
  local has_only_suites = false
  for _, cls in ipairs(test_suites) do
    if cls.__only then
      has_only_suites = true
      break
    end
  end

  -- Run global beforeAll hooks
  for _, hook in ipairs(global_before_all_hooks) do
    local success, err = pcall(hook)
    if not success then
      error('Error in global beforeAll hook: ' .. tostring(err), 2)
    end
  end

  logger.prelude()
  for _, cls in ipairs(test_suites) do
    -- Skip suites marked as skip
    if cls.__skip then
      -- Don't run
    -- If there are 'only' suites, only run those
    elseif has_only_suites and not cls.__only then
      -- Don't run
    -- Apply name filter if provided
    elseif not filter or cls.__name:match(filter) then
      local test_object = cls(
        cls.__name,
        cls.__tests_data,
        cls.__nested_suites or {},
        cls.__name_path or {cls.__name}
      )
      local failed_tests, tests_ran = test_object:run_tests(logger)
      total_failure_count = total_failure_count + failed_tests
      total_test_count = total_test_count + tests_ran
    end
  end
  logger.finale(total_failure_count, total_test_count)

  -- Run global afterAll hooks
  for _, hook in ipairs(global_after_all_hooks) do
    pcall(hook)
  end

  return total_failure_count, total_test_count
end

return {
  describe = describe,
  it = it,
  test = test,
  is_assertion_failure = is_assertion_failure,
  expect = expect,
  expect_extend = expect_extend,
  before_each = before_each,
  after_each = after_each,
  before_all = before_all,
  after_all = after_all,
  global_before_all = global_before_all,
  global_after_all = global_after_all,
  run_tests = run_tests,
  test_suites = test_suites,
  matchers = custom_matchers,
}

