require 'ext/string'
require 'lx/base'
require 'lx/terminal_colors'
local class = require 'lx/class'

-- Utilities

local function table_to_string(t)
  local s = '{'
  local first = true
  for k, v in pairs(t) do
    if first then
      s = s .. tostring(k) .. ' = ' .. tostring(v)
      first = false
    else
      s = s .. ', ' .. tostring(k) .. ' = ' .. tostring(v)
    end
  end
  return s .. '}'
end

--------------------------------------------------------------------------------
local fmt = 'expected\n  %s\nto %s\n  %s'
function EXPECT_THAT(actual, predicate)
  result, act, msg, nmsg, exp = predicate(actual, false)
  if not result then
    error(fmt:format(act, msg, exp))
  end
end

function EXPECT_TRUE(actual)
  EXPECT_THAT(actual, Equals(true))
end

function EXPECT_FALSE(actual)
  EXPECT_THAT(actual, Equals(false))
end

function EXPECT_EQ(actual, expected)
  EXPECT_THAT(actual, Equals(expected))
end

function EXPECT_NE(actual, expected)
  EXPECT_THAT(actual, Not(Equals(expected)))
end

function Not(predicate)
  return function(actual)
    local result, act, msg, nmsg, exp = predicate(actual)
    return not result, act, nmsg, msg, exp
  end
end

function Equals(expected)
  return function(actual)
    local result = (actual == expected)
    return
      result,
      tostring(actual),
      'be equal to',
      'be not equal to',
      tostring(expected)
  end
end

function GreaterThan(expected)
  return function(actual)
    local result = (actual > expected)
    return
      result,
      tostring(actual),
      'be greater than',
      'be not greater than',
      tostring(expected)
  end
end

function GreaterThanOrEqual(expected)
  return function(actual)
    local result = (actual >= expected)
    return
      result,
      tostring(actual),
      'be greater than or equal to',
      'be not greater than or equal to',
      tostring(expected)
  end
end

function LessThan(expected)
  return function(actual)
    local result = (actual < expected)
    return
      result,
      tostring(actual),
      'be less than',
      'be not less than',
      tostring(expected)
  end
end

function LessThanOrEqual(expected)
  return function(actual)
    local result = (actual <= expected)
    return
      result,
      tostring(actual),
      'be less than or equal to',
      'be not less than or equal to',
      tostring(expected)
  end
end

function StartsWith(expected)
  return function(actual)
    local result = actual:startswith(expected)
    return
      result,
      tostring(actual),
      'start with',
      'not start with',
      tostring(expected)
  end
end

function EndsWith(expected)
  return function(actual)
    local result = actual:endswith(expected)
    return
      result,
      tostring(actual),
      'end with',
      'not end with',
      tostring(expected)
  end
end

function Listwise(predicate_generator, expected)
  return function(actual)
    local result = true
    local act, msg, nmsg, exp
    local act_list, exp_list = {}, {}
    for i=1, max(#actual, #expected) do
      local predicate = predicate_generator(expected[i])
      local local_result
      local_result, act, msg, nmsg, exp = predicate(actual[i])
      act_list[i], exp_list[i] = act, exp
      result = result and local_result
    end
    return result,
           '{' .. (','):join(act_list) .. '}',
           msg .. ' the value at every index of',
           'not to ' .. msg .. ' the value at every index of',
           '{' .. (','):join(exp_list) .. '}'
  end
end

function Tablewise(predicate_generator, expected)
  return function(actual)
    local result = true
    local act, msg, nmsg, exp
    local act_list, exp_list = {}, {}
    local keys = collect_keys({}, actual, expected)
    for k, _ in pairs(keys) do
      local predicate = predicate_generator(expected[k])
      local local_result
      local_result, act, msg, nmsg, exp = predicate(actual[k])
      result = result and local_result
    end
    return result,
           table_to_string(actual),
           msg .. ' the value at every key of',
           'not to ' .. msg .. ' the value at every key of',
           table_to_string(expected)
  end
end

-- Make the results printing a coroutine.

class 'Test' {
  setup = noop;
  teardown = noop;

  run_tests = function(self)
    -- Gather list of tests
    local tests = {}
    -- classes need __pairs metamethods.
    for test_name, test in pairs(self) do
    end

    for test_name, test in pairs(self) do
    end

    local ok, err = pcall(test)
  end
}

-- This is a list of classes that have been registered with unit.
local unit_test_suite = {}
function TestCase(name)
  local test_case = {}
  test_case.name = name
  table.insert(unit_test_suite, test_case)
  return setmetatable({}, {
    __call = function(self, test_case_table)
      test_case.tests = test_case_table
    end
  })
end

function run_unit_tests(test_suite)
  local total_failure_count = 0
  local total_test_count = 0
  local failure_list = {}
  for _, test_case in ipairs(unit_test_suite) do
    local test_count = 0
    for name, test in pairs(test_case.tests) do
      if name:startswith('test_') then
        test_count = test_count + 1
        total_test_count = total_test_count + 1
      end
    end
    printf('%s[==========]%s Running %s tests from %s%s%s',
            color(green), reset(), test_count, color(bright_cyan), test_case.name, reset())
    local test_number = 0
    local failure_count = 0
    for name, test in pairs(test_case.tests) do
      if name:startswith('test_') then
        test_number = test_number + 1
        printf('%s[ Run      ] %s%s.%s%s',
               color(green), color(bright_cyan), test_case.name, name, reset())
        local ok, err = pcall(test)
        if ok then
          printf('%s[       OK ] %s%s.%s%s',
                 color(green), color(bright_cyan), test_case.name, name, reset())
        else
          total_failure_count = total_failure_count + 1
          failure_count = failure_count + 1
          table.insert(failure_list, test_case.name .. '.' .. name)
          printf('%s[  FAILURE ] %s%s.%s%s\n%s',
                 color(red), color(bright_cyan), test_case.name, name, reset(), err)
        end
      end
    end
    if failure_count == 0 then
      printf('%s[==========]%s All %s tests succeeded!',
             color(green), reset(), test_case.name)
    else
      printf('%s[==========]%s %s / %s failed.',
             color(red), reset(), failure_count, test_count)
    end
      print()
  end
  if total_failure_count == 0 then
    printf('%s[==========]%s All tests succeeded!',
           color(green), reset())
  else
    printf('%s[==========]%s %s / %s failed.',
           color(red), reset(), total_failure_count, total_test_count)
    for i, v in ipairs(failure_list) do
      printf('%s[  FAILED  ] %s%s',
             color(red), v, reset())
    end
  end
end

function print_test_suite_results(results)
end

function RunUnitTests()
  local results = run_unit_tests(unit_test_suite)
  print_test_suite_results(results)
end
