-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

return require 'llx/src/flatten_submodules' {
  require 'llx/src/types/boolean',
  require 'llx/src/types/float',
  require 'llx/src/types/function',
  require 'llx/src/types/integer',
  require 'llx/src/types/nil',
  require 'llx/src/types/number',
  require 'llx/src/types/string',
  require 'llx/src/types/table',
  require 'llx/src/types/thread',
  require 'llx/src/types/userdata',

  require 'llx/src/types/list',
  require 'llx/src/types/set',

  require 'llx/src/types/matchers'
}