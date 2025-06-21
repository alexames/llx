-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local strict = require 'llx.strict'

local lock <close> = strict.lock_global_table()

return require 'llx.flatten_submodules' {
  require 'llx.check_arguments',
  require 'llx.class',
  require 'llx.core',
  require 'llx.getclass',
  require 'llx.isinstance',
  require 'llx.repr',
  require 'llx.schema',
  require 'llx.strict',
  require 'llx.string_view',
  require 'llx.tointeger',
  require 'llx.types',
  coroutine = require 'llx.coroutine',
  debug = require 'llx.debug',
  decorator = require 'llx.decorator',
  environment = require 'llx.environment',
  exceptions = require 'llx.exceptions',
  flow_control = require 'llx.flow_control',
  functional = require 'llx.functional',
  hash = require 'llx.hash',
  method = require 'llx.method',
  operators = require 'llx.operators',
  property = require 'llx.property',
  proxy = require 'llx.proxy',
  truthy = require 'llx.truthy',
  type_check_decorator = require 'llx.type_check_decorator',
}
