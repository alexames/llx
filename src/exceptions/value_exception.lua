require 'llx/src/class'
require 'llx/src/exceptions/exception'

ValueException =
    class 'InvalidArgumentException' : extends(Exception) {
  __init = function(self, what, level)
    Exception.__init(self, what, (level or 1) + 1)
  end,
}
