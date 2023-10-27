require 'lx/base'

local test = require 'unit/test'
local test_logger = require 'unit/test_logger'

-- This is a list of classes that have been registered with unit.
local global_test_suites = Table{}
function test_class(name)
  return function(class_definition)
    local cls = class(name):extends(test.Test)(class_definition)
    global_test_suites:insert(cls)
  end
end

function run_unit_tests(test_suites, logger)
  test_suites = test_suites or global_test_suites
  logger = logger or test_logger.TestLogger()
  local total_failure_count = 0
  local total_test_count = 0
  local failure_list = Table()
  logger.prelude()
  for _, cls in ipairs(test_suites) do
    local test_object = cls()
    local failed_tests, tests_ran = test_object:run_tests(logger)
    total_failure_count = total_failure_count + failed_tests
    total_test_count = total_test_count + tests_ran
  end
  logger.finale(total_failure_count, total_test_count)
end

return {
  test_class=test_class,
  run_unit_tests=run_unit_tests,
}
