require 'ext/string'
require 'ext/table'
require 'lx/base'
require 'lx/terminal_colors'
require 'lx/matchers'

local class = require 'lx/class'

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
  end;
}

function test(name)
  return 'test_' .. name
end

function test_class(name)
  return function(class_definition)
    RegisterTestClass(class(name):extends(Test)(class_definition))
  end
end

-- This is a list of classes that have been registered with unit.
local unit_test_suite = Table{}
function RegisterTestClass(test_class)
  unit_test_suite:insert(test_class)
end

function run_unit_tests(test_suite)
  local total_failure_count = 0
  local total_test_count = 0
  local failure_list = {}
  for _, test_class in ipairs(unit_test_suite) do
    local test_count = 0
    for name, test in pairs(test_class) do
      if type(name) == 'string' and name:startswith('test_') then
        test_count = test_count + 1
        total_test_count = total_test_count + 1
      end
    end
    -- test_class:run_tests()
    printf('%s[==========]%s Running %s tests from %s%s%s',
            color(green), reset(), test_count, color(bright_cyan), 
            -- This needs to be fixed.
            tostring(test_class),
            reset())
    local test_number = 0
    local failure_count = 0
    for name, test in pairs(test_class) do
      if type(name) == 'string' and name:startswith('test_') then
        test_number = test_number + 1
        printf('%s[ Run      ] %s%s.%s%s',
               color(green), color(bright_cyan), test_class.__name, name, reset())
        local ok, err = pcall(test)
        if ok then
          printf('%s[       OK ] %s%s.%s%s',
                 color(green), color(bright_cyan), test_class.__name, name, reset())
        else
          total_failure_count = total_failure_count + 1
          failure_count = failure_count + 1
          table.insert(failure_list, (test_class.__name or tostring(test_class)) .. '.' .. name)
          printf('%s[  FAILURE ] %s%s.%s%s\n%s',
                 color(red), color(bright_cyan), test_class.__name, name, reset(), err)
        end
      end
    end
    if failure_count == 0 then
      printf('%s[==========]%s All %s tests succeeded!',
             color(green), reset(), test_class)
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
