-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local strict = require 'llx/src/strict'

local lock <close> = strict.lock_global_table()

return require 'llx/src/flatten_submodules' {
  require 'llx/src/class',
  require 'llx/src/check_arguments',
  require 'llx/src/types',
  require 'llx/src/isinstance',
  require 'llx/src/schema',
  require 'llx/src/tointeger',
  require 'llx/src/repr',
  require 'llx/src/core',
  coroutine = require 'llx/src/coroutine',
  debug = require 'llx/src/debug',
  decorator = require 'llx/src/decorator',
  environment = require 'llx/src/environment',
  exceptions = require 'llx/src/exceptions',
  flow_control = require 'llx/src/flow_control',
  functional = require 'llx/src/functional',
  hash = require 'llx/src/hash',
  method = require 'llx/src/method',
  operators = require 'llx/src/operators',
  property = require 'llx/src/property',
  proxy = require 'llx/src/proxy',
  truthy = require 'llx/src/truthy',
  type_check_decorator = require 'llx/src/type_check_decorator',
}
