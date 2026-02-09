-- Root module tests
require 'llx.tests.test_check_arguments'
require 'llx.tests.test_class'
require 'llx.tests.test_core'
require 'llx.tests.test_functional'

-- types/ tests
require 'llx.tests.types.test_list'
require 'llx.tests.types.test_list_methods'

-- flow_control/ tests
require 'llx.tests.flow_control.test_trycatch'

-- unit/ tests
require 'llx.tests.unit.test_mock'
require 'llx.tests.unit.test_unit'
require 'llx.tests.unit.test_unit_features'
