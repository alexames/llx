-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

return require 'llx/flatten_submodules' {
  require 'llx/types/boolean',
  require 'llx/types/float',
  require 'llx/types/function',
  require 'llx/types/integer',
  require 'llx/types/nil',
  require 'llx/types/number',
  require 'llx/types/string',
  require 'llx/types/table',
  require 'llx/types/thread',
  require 'llx/types/userdata',

  require 'llx/types/list',
  require 'llx/types/set',

  require 'llx/types/matchers'
}