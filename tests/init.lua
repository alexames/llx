-- Root module tests
require 'llx.tests.test_cache'
require 'llx.tests.test_check_arguments'
require 'llx.tests.test_class'
require 'llx.tests.test_core'
require 'llx.tests.test_coroutine'
require 'llx.tests.test_decorator'
require 'llx.tests.test_enum'
require 'llx.tests.test_environment'
require 'llx.tests.test_flatten_submodules'
require 'llx.tests.test_functional'
require 'llx.tests.test_functional_combinators'
require 'llx.tests.test_functional_iterators'
require 'llx.tests.test_string_utils'
require 'llx.tests.test_table_utils'
require 'llx.tests.test_set_utils'
require 'llx.tests.test_getclass'
require 'llx.tests.test_hash'
require 'llx.tests.test_mathx'
require 'llx.tests.test_hash_table'
require 'llx.tests.test_isinstance'
require 'llx.tests.test_method'
require 'llx.tests.test_operators'
require 'llx.tests.test_property'
require 'llx.tests.test_proxy'
require 'llx.tests.test_repr'
require 'llx.tests.test_schema'
require 'llx.tests.test_signature'
require 'llx.tests.test_tointeger'
require 'llx.tests.test_tostringf'
require 'llx.tests.test_tracing'
require 'llx.tests.test_truthy'
require 'llx.tests.test_tuple'
require 'llx.tests.test_type_check_decorator'

-- debug/ tests
require 'llx.tests.debug.test_debug'

-- exceptions/ tests
require 'llx.tests.exceptions.test_exceptions'

-- flow_control/ tests
require 'llx.tests.flow_control.test_catch'
require 'llx.tests.flow_control.test_switchcase'
require 'llx.tests.flow_control.test_trycatch'

-- strict/ tests
require 'llx.tests.strict.test_strict'

-- types/ tests
require 'llx.tests.types.test_list'
require 'llx.tests.types.test_list_methods'
require 'llx.tests.types.test_matchers'
require 'llx.tests.types.test_type_checkers'

-- bytecode/ tests
require 'llx.tests.bytecode.lua54.test_bytestream'
require 'llx.tests.bytecode.lua54.test_constants'
require 'llx.tests.bytecode.lua54.test_enum'
require 'llx.tests.bytecode.lua54.test_typetags'
require 'llx.tests.bytecode.lua54.test_opcodes'
require 'llx.tests.bytecode.lua54.test_instructions'
require 'llx.tests.bytecode.lua54.test_bcode'
require 'llx.tests.bytecode.lua54.test_util'

-- unit/ tests
require 'llx.tests.unit.test_mock'
require 'llx.tests.unit.test_unit'
require 'llx.tests.unit.test_unit_features'
