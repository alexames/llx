-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

return require 'llx.flatten_submodules' {
  require 'llx.exceptions.exception',
  require 'llx.exceptions.exception_group',
  require 'llx.exceptions.invalid_argument_exception',
  require 'llx.exceptions.schema_exception',
  require 'llx.exceptions.not_implemented_exception',
  require 'llx.exceptions.value_exception',
}
