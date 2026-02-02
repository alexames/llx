--- Unit testing framework for Lua.
-- Provides access to core test API, mocks, test registration, and execution.
--
-- @module llx.unit
-- @usage
-- local unit = require 'llx.unit'
-- unit.describe('MyTest', function()
--   unit.it('should work', function()
--     unit.expect(1 + 1).to.be_equal_to(2)
--   end)
-- end)

local mock = require 'llx.unit.mock'
local runner = require 'llx.unit.runner'
local test = require 'llx.unit.test'
local test_api = require 'llx.unit.test_api'
local matchers = require 'llx.unit.matchers'

--- Creates a test environment with fallback to another environment.
-- @param fallback_env The environment to fall back to for undefined variables
-- @return A new environment table
local function create_test_env(fallback_env)
  local env = {
    Mock = mock.Mock,
    spy_on = mock.spy_on,
    run_unit_tests = runner.run_unit_tests,
    Test = test.Test,
    test = test.test,
    describe = test_api.describe,
    it = test_api.it,
    expect = test_api.expect,
    before_each = test_api.before_each,
    after_each = test_api.after_each,
    before_all = test_api.before_all,
    after_all = test_api.after_all,
    global_before_all = test_api.global_before_all,
    global_after_all = test_api.global_after_all,
    run_tests = test_api.run_tests,
    matchers = test_api.matchers,
    matchers_module = matchers,
  }
  return setmetatable(env, {
    __index = fallback_env,
    __newindex = fallback_env,
  })
end

return {
  --- Mock class for creating mock functions.
  -- @see llx.unit.mock.Mock
  Mock = mock.Mock,
  --- Creates a spy on an existing object method.
  -- @see llx.unit.mock.spy_on
  spy_on = mock.spy_on,
  --- Executes all registered test suites.
  -- @see llx.unit.runner.run_unit_tests
  run_unit_tests = runner.run_unit_tests,
  --- Test class for creating test instances.
  Test = test.Test,
  --- Function to register a test.
  test = test.test,
  --- Defines a test suite.
  describe = test_api.describe,
  --- Defines a test case.
  it = test_api.it,
  --- Creates an expectation for assertions.
  expect = test_api.expect,
  --- Runs a function before each test in the current suite.
  before_each = test_api.before_each,
  --- Runs a function after each test in the current suite.
  after_each = test_api.after_each,
  --- Runs a function once before all tests in the current suite.
  before_all = test_api.before_all,
  --- Runs a function once after all tests in the current suite.
  after_all = test_api.after_all,
  --- Runs a function once before all test suites.
  global_before_all = test_api.global_before_all,
  --- Runs a function once after all test suites.
  global_after_all = test_api.global_after_all,
  --- Runs all tests in the current context.
  run_tests = test_api.run_tests,
  --- Table of matcher functions.
  matchers = test_api.matchers,
  --- Module containing matcher functions (snake_case).
  matchers_module = matchers,
  --- Creates a test environment with fallback to another environment.
  create_test_env = create_test_env,
}
