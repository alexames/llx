rockspec_format = "3.0"
package = "llx"
version = "1.0.0-1"

source = {
   url = "git://github.com/alexames/llx.git",
   tag = "v1.0.0",
}

description = {
   summary = "Lua Extension Library",
   detailed = [[
A comprehensive Lua utility library providing extensions and utilities for Lua development.
Includes object-oriented class system, functional programming utilities, type checking,
schema validation, exception handling, unit testing, and more.
   ]],
   homepage = "https://github.com/alexames/llx",
   license = "MIT",
   maintainer = "Alexander Ames <Alexander.Ames@gmail.com>",
   labels = {
      "oop",
      "class",
      "functional",
      "type-checking",
      "schema",
      "exceptions",
      "utilities",
      "unit-testing",
   },
}

dependencies = {
   "lua >= 5.4",
}

test = {
   type = "command",
   command = "lua test.lua",
}

build = {
   type = "builtin",
   modules = {
      -- Main entry point
      ["llx"] = "src/init.lua",

      -- Core modules
      ["llx.cache"] = "src/cache.lua",
      ["llx.check_arguments"] = "src/check_arguments.lua",
      ["llx.class"] = "src/class.lua",
      ["llx.core"] = "src/core.lua",
      ["llx.coroutine"] = "src/coroutine.lua",
      ["llx.decorator"] = "src/decorator.lua",
      ["llx.enum"] = "src/enum.lua",
      ["llx.environment"] = "src/environment.lua",
      ["llx.flatten_submodules"] = "src/flatten_submodules.lua",
      ["llx.functional"] = "src/functional.lua",
      ["llx.getclass"] = "src/getclass.lua",
      ["llx.hash"] = "src/hash.lua",
      ["llx.hash_table"] = "src/hash_table.lua",
      ["llx.isinstance"] = "src/isinstance.lua",
      ["llx.method"] = "src/method.lua",
      ["llx.operators"] = "src/operators.lua",
      ["llx.property"] = "src/property.lua",
      ["llx.proxy"] = "src/proxy.lua",
      ["llx.repr"] = "src/repr.lua",
      ["llx.schema"] = "src/schema.lua",
      ["llx.signature"] = "src/signature.lua",
      ["llx.string_view"] = "src/string_view.lua",
      ["llx.tointeger"] = "src/tointeger.lua",
      ["llx.tostringf"] = "src/tostringf.lua",
      ["llx.tracing"] = "src/tracing.lua",
      ["llx.truthy"] = "src/truthy.lua",
      ["llx.tuple"] = "src/tuple.lua",
      ["llx.type_check_decorator"] = "src/type_check_decorator.lua",

      -- debug submodule
      ["llx.debug"] = "src/debug/init.lua",
      ["llx.debug.dump_value"] = "src/debug/dump_value.lua",
      ["llx.debug.print"] = "src/debug/print.lua",
      ["llx.debug.terminal_colors"] = "src/debug/terminal_colors.lua",
      ["llx.debug.trace"] = "src/debug/trace.lua",

      -- exceptions submodule
      ["llx.exceptions"] = "src/exceptions/init.lua",
      ["llx.exceptions.exception"] = "src/exceptions/exception.lua",
      ["llx.exceptions.exception_group"] = "src/exceptions/exception_group.lua",
      ["llx.exceptions.index_error"] = "src/exceptions/index_error.lua",
      ["llx.exceptions.invalid_argument_exception"] = "src/exceptions/invalid_argument_exception.lua",
      ["llx.exceptions.not_implemented_exception"] = "src/exceptions/not_implemented_exception.lua",
      ["llx.exceptions.runtime_error"] = "src/exceptions/runtime_error.lua",
      ["llx.exceptions.schema_exception"] = "src/exceptions/schema_exception.lua",
      ["llx.exceptions.type_error"] = "src/exceptions/type_error.lua",
      ["llx.exceptions.value_exception"] = "src/exceptions/value_exception.lua",

      -- flow_control submodule
      ["llx.flow_control"] = "src/flow_control/init.lua",
      ["llx.flow_control.catch"] = "src/flow_control/catch.lua",
      ["llx.flow_control.switchcase"] = "src/flow_control/switchcase.lua",
      ["llx.flow_control.trycatch"] = "src/flow_control/trycatch.lua",

      -- strict submodule
      ["llx.strict"] = "src/strict/init.lua",
      ["llx.strict.disallow_globals"] = "src/strict/disallow_globals.lua",

      -- types submodule
      ["llx.types"] = "src/types/init.lua",
      ["llx.types.boolean"] = "src/types/boolean.lua",
      ["llx.types.float"] = "src/types/float.lua",
      ["llx.types.function"] = "src/types/function.lua",
      ["llx.types.integer"] = "src/types/integer.lua",
      ["llx.types.list"] = "src/types/list.lua",
      ["llx.types.matchers"] = "src/types/matchers.lua",
      ["llx.types.nil"] = "src/types/nil.lua",
      ["llx.types.number"] = "src/types/number.lua",
      ["llx.types.set"] = "src/types/set.lua",
      ["llx.types.string"] = "src/types/string.lua",
      ["llx.types.table"] = "src/types/table.lua",
      ["llx.types.thread"] = "src/types/thread.lua",
      ["llx.types.userdata"] = "src/types/userdata.lua",

      -- bytecode submodule
      ["llx.bytecode.bcode"] = "src/bytecode/bcode.lua",
      ["llx.bytecode.bytestream"] = "src/bytecode/bytestream.lua",
      ["llx.bytecode.constants"] = "src/bytecode/constants.lua",
      ["llx.bytecode.enum"] = "src/bytecode/enum.lua",
      ["llx.bytecode.instructions"] = "src/bytecode/instructions.lua",
      ["llx.bytecode.main"] = "src/bytecode/main.lua",
      ["llx.bytecode.opcodes"] = "src/bytecode/opcodes.lua",
      ["llx.bytecode.typetags"] = "src/bytecode/typetags.lua",
      ["llx.bytecode.util"] = "src/bytecode/util.lua",

      -- experimental submodule
      ["llx.experimental.export"] = "src/experimental/export.lua",
      ["llx.experimental.man"] = "src/experimental/man.lua",

      -- unit testing submodule
      ["llx.unit"] = "src/unit/init.lua",
      ["llx.unit.test"] = "src/unit/test.lua",
      ["llx.unit.test_api"] = "src/unit/test_api.lua",
      ["llx.unit.test_logger"] = "src/unit/test_logger.lua",
      ["llx.unit.matchers"] = "src/unit/matchers.lua",
      ["llx.unit.mock"] = "src/unit/mock.lua",
      ["llx.unit.runner"] = "src/unit/runner.lua",
   },
   copy_directories = {
      "docs",
   },
}
