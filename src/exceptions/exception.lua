-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>
require 'llx/src/class'

Exception = class 'Exception' {
  __init = function(self, what, level)
    self.what = debug.traceback(what, (level or 1) + 1)
  end,

  __tostring = function(self)
    return self.__name .. ':' .. self.what
  end,
}
