-- runner.lua
-- Test registration and execution logic
--
-- @module llx.unit.runner

local test_logger = require 'llx.unit.test_logger'

-- Import test API suites
local test_api = require 'llx.unit.test_api'

--- Executes all registered test suites (describe/it style).
-- @param[opt] filter A string to match against test suite names
-- @param[opt] logger An optional logger object to capture output
-- @return total_failure_count The number of failed tests
-- @return total_test_count The total number of tests run
local function run_unit_tests(filter, logger)
  local hierarchical_logger = logger or test_logger.HierarchicalLogger()
  local total_failure_count = 0
  local total_test_count = 0

  hierarchical_logger.prelude()

  for _, cls in ipairs(test_api.test_suites) do
    if not filter or cls.__name:match(filter) then
      local test_object = cls(
        cls.__name,
        cls.__tests_data,
        cls.__nested_suites or {},
        cls.__name_path or {cls.__name}
      )
      local failed_tests, tests_ran = test_object:run_tests(hierarchical_logger)
      total_failure_count = total_failure_count + failed_tests
      total_test_count = total_test_count + tests_ran
    end
  end

  hierarchical_logger.finale(total_failure_count, total_test_count)

  return total_failure_count, total_test_count
end

return {
  run_unit_tests = run_unit_tests,
}
