-- test_logger.lua
-- Console-based test output formatter
--
-- @module unit.test_logger

local llx = require 'llx'
local class = llx.class
local red = llx.debug.red
local green = llx.debug.green
local bright_cyan = llx.debug.bright_cyan
local color = llx.debug.color
local reset = llx.debug.reset
local printf = llx.printf

--- Logger used for displaying test results to stdout.
TestLogger = class 'TestLogger' {
  --- Returns the current test suite name.
  test_suite_name = function(self)
    return self.test_suite.__class_name
  end;

  --- Called once before any tests run.
  prelude = function() end;

  --- Prints the beginning of a test class.
  -- @param test_suite The test class object
  class_preamble = function(test_suite)
    printf('%s[==========]%s Running %s tests from %s%s%s',
            color(green), reset(), #test_suite:tests(), color(bright_cyan),
            test_suite:name(), reset())
  end;

  --- Prints the beginning of a single test.
  test_begin = function(test_suite, test_name)
    printf('%s[ Run      ] %s%s.%s%s',
           color(green), color(bright_cyan), test_suite:name(), table.concat(test_name, '.'), reset())
  end;

  --- Prints the result of a test case.
  test_end = function(test_suite, test_name, successful, err)
    if successful then
      printf('%s[       OK ] %s%s.%s%s',
             color(green), color(bright_cyan), test_suite:name(), table.concat(test_name, '.'), reset())
    else
      printf('%s[  FAILURE ] %s%s.%s%s\n%s',
             color(red), color(bright_cyan), test_suite:name(), table.concat(test_name, '.'), reset(), err)
    end
  end;

  --- Prints summary of the test class.
  -- @param test_suite The test class
  -- @param failure_count Number of failing tests
  class_conclusion = function(test_suite, failure_count)
    if failure_count == 0 then
      printf('%s[==========]%s All %s tests succeeded!',
             color(green), reset(), test_suite:name())
    else
      printf('%s[==========]%s %s / %s failed.',
             color(red), reset(), failure_count, #test_suite:tests())
    end
    print()
  end;

  --- Prints final global test results.
  finale = function(total_failure_count, total_test_count)
    if total_failure_count == 0 then
      printf('%s[==========]%s All tests succeeded!',
             color(green), reset())
    else
      printf('%s[==========]%s %s / %s failed.',
             color(red), reset(), total_failure_count, total_test_count)
    end
  end;
}

-- Module-level variable to store the current HierarchicalLogger instance
local current_hierarchical_logger = nil

--- Builds a hierarchical tree structure from test name paths
-- @param tests List of tests with name_path arrays
-- @param suite_path The path of the current suite
-- @return Tree structure with describe blocks and tests
local function build_test_tree(tests, suite_path)
  local tree = {}
  local suite_path_len = #suite_path
  
  for _, test in ipairs(tests) do
    if not test.name_path then
      -- Fallback for tests without name_path
      table.insert(tree, {type = 'test', data = test})
    else
      -- Find where this test belongs in the tree
      local current = tree
      local test_path = test.name_path
      
      -- Navigate/create the path for nested describe blocks
      for i = suite_path_len + 1, #test_path - 1 do
        local segment = test_path[i]
        local found = false
        
        -- Look for existing describe block at this level
        for _, item in ipairs(current) do
          if item.type == 'describe' and item.name == segment then
            current = item.children
            found = true
            break
          end
        end
        
        -- Create new describe block if not found
        if not found then
          local new_describe = {
            type = 'describe',
            name = segment,
            children = {}
          }
          table.insert(current, new_describe)
          current = new_describe.children
        end
      end
      
      -- Add the test at the appropriate level
      table.insert(current, {type = 'test', data = test})
    end
  end
  
  return tree
end

--- Checks if a tree node has any failing descendants
-- @param item Tree item (describe block or test)
-- @return true if item or any descendant has failed
local function has_failing_descendant(item)
  if item.type == 'test' then
    return not item.data.passed
  elseif item.type == 'describe' then
    for _, child in ipairs(item.children) do
      if has_failing_descendant(child) then
        return true
      end
    end
    return false
  end
  return false
end

--- Recursively prints a tree node
-- @param items List of tree items (describe blocks or tests)
-- @param indent Current indentation level
local function print_tree(items, indent)
  for _, item in ipairs(items) do
    local indent_str = string.rep('  ', indent)
    if item.type == 'describe' then
      -- Check if this describe block has any failing descendants
      local has_failures = has_failing_descendant(item)
      local describe_color = has_failures and red or green
      local describe_symbol = has_failures and '-' or '+'
      printf('%s%s%s%s %s%s', indent_str, color(describe_color), describe_symbol, reset(), item.name, reset())
      print_tree(item.children, indent + 1)
    elseif item.type == 'test' then
      local test = item.data
      if test.passed then
        printf('%s%s+%s %s%s', indent_str, color(green), reset(), test.name, reset())
      else
        printf('%s%s-%s %s%s', indent_str, color(red), reset(), test.name, reset())
        -- Print error details
        if test.error then
          local error_lines = {}
          for line in test.error:gmatch('[^\r\n]+') do
            table.insert(error_lines, line)
          end
          -- Print first few lines of error, indented
          for i = 1, math.min(5, #error_lines) do
            printf('%s  %s', indent_str, error_lines[i])
          end
          if #error_lines > 5 then
            printf('%s  ... (%d more lines)', indent_str, #error_lines - 5)
          end
        end
      end
    end
  end
end

--- Hierarchical logger for displaying test results with nested describe blocks.
HierarchicalLogger = class 'HierarchicalLogger' {
  __init = function(self)
    self.test_suites = {}
    self.current_suite = nil
    self.total_passed = 0
    self.total_failed = 0
    self.total_tests = 0
    current_hierarchical_logger = self
  end;

  --- Called once before any tests run.
  prelude = function() end;

  --- Prints the beginning of a test class.
  -- @param test_suite The test class object
  class_preamble = function(test_suite)
    if not current_hierarchical_logger then
      error('HierarchicalLogger instance not found')
    end
    -- Get nested suites if available
    local nested_suites = {}
    if test_suite._nested_suites then
      for _, nested in ipairs(test_suite._nested_suites) do
        table.insert(nested_suites, nested)
      end
    end
    current_hierarchical_logger.current_suite = {
      name = test_suite:name(),
      name_path = test_suite._name_path or {test_suite:name()},
      tests = {},
      nested_suites = nested_suites,
      passed = 0,
      failed = 0,
    }
    table.insert(current_hierarchical_logger.test_suites, current_hierarchical_logger.current_suite)
  end;

  --- Prints the beginning of a single test.
  test_begin = function(test_suite, test_name)
    -- Hierarchical logger doesn't print test begin, we'll print it in test_end
  end;

  --- Prints the result of a test case.
  test_end = function(test_suite, test_name, successful, err)
    if not current_hierarchical_logger then
      error('HierarchicalLogger instance not found')
    end
    -- test_name is already a path array, store it as-is
    local test_info = {
      name_path = test_name,
      name = test_name[#test_name], -- Just the last element (local name)
      passed = successful,
      error = err,
    }
    table.insert(current_hierarchical_logger.current_suite.tests, test_info)
    
    if successful then
      current_hierarchical_logger.current_suite.passed = current_hierarchical_logger.current_suite.passed + 1
      current_hierarchical_logger.total_passed = current_hierarchical_logger.total_passed + 1
    else
      current_hierarchical_logger.current_suite.failed = current_hierarchical_logger.current_suite.failed + 1
      current_hierarchical_logger.total_failed = current_hierarchical_logger.total_failed + 1
    end
    current_hierarchical_logger.total_tests = current_hierarchical_logger.total_tests + 1
  end;

  --- Prints summary of the test class.
  -- @param test_suite The test class
  -- @param failure_count Number of failing tests
  class_conclusion = function(test_suite, failure_count)
    -- We'll print this in finale
  end;

  --- Prints final global test results.
  finale = function(total_failure_count, total_test_count)
    if not current_hierarchical_logger then
      error('HierarchicalLogger instance not found')
    end
    
    -- Print each test suite hierarchically
    for _, suite in ipairs(current_hierarchical_logger.test_suites) do
      -- Get the suite's base name (last element of name_path)
      local suite_name = suite.name_path[#suite.name_path]
      local suite_color = suite.failed > 0 and red or green
      local suite_symbol = suite.failed > 0 and '-' or '+'
      
      -- Print suite header
      printf('%s%s%s %s%s', color(suite_color), suite_symbol, reset(), suite_name, reset())
      
      -- Build tree from tests
      local tree = build_test_tree(suite.tests, suite.name_path)
      
      -- Print the tree
      print_tree(tree, 1)
      print()
    end
    
    -- Print summary
    print()
    local all_passed = total_failure_count == 0
    local summary_color = all_passed and green or red
    
    local suite_count = #current_hierarchical_logger.test_suites
    local passed_suites = 0
    local failed_suites = 0
    for _, suite in ipairs(current_hierarchical_logger.test_suites) do
      if suite.failed == 0 then
        passed_suites = passed_suites + 1
      else
        failed_suites = failed_suites + 1
      end
    end
    
    printf('Test Suites: %s%d %s, %d total',
           color(summary_color),
           all_passed and passed_suites or failed_suites,
           all_passed and 'passed' or 'failed',
           suite_count)
    print()
    
    printf('Tests:       %s%d %s, %d total',
           color(summary_color),
           all_passed and total_test_count or total_failure_count,
           all_passed and 'passed' or 'failed',
           total_test_count)
    print()
    
    if all_passed then
      printf('%s+%s All tests passed!', color(green), reset())
    else
      printf('%s-%s %d test(s) failed', color(red), reset(), total_failure_count)
    end
    print()
  end;
}

return {
  TestLogger = TestLogger,
  HierarchicalLogger = HierarchicalLogger,
}
