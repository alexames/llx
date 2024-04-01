-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/class'
require 'llx/src/exceptions/exception'

NotImplementedException = class 'NotImplementedException' : extends(Exception) {
  __init = function(self, what, level)
    Exception.__init(self, what, (level or 1) + 1)
  end,
}
