-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>
require 'llx/src/class'

Exception = class 'Exception' {
  __init = function(self, what, level)
    self.what = what
    self.traceback = debug.traceback('', (level or 1) + 1)
  end,

  __tostring = function(self)
    return self.__name .. ':' .. self.what .. self.traceback
  end,
}
