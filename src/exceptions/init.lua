-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

return require 'llx.flatten_submodules' {
  require 'llx.exceptions.attribute_error',
  require 'llx.exceptions.exception',
  require 'llx.exceptions.exception_group',
  require 'llx.exceptions.index_error',
  require 'llx.exceptions.invalid_argument_exception',
  require 'llx.exceptions.not_implemented_exception',
  require 'llx.exceptions.overload_resolution_exception',
  require 'llx.exceptions.runtime_error',
  require 'llx.exceptions.schema_exception',
  require 'llx.exceptions.type_error',
  require 'llx.exceptions.value_exception',
}
