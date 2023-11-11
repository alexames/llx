require 'llx/src/class'
require 'llx/src/exceptions/exception'

InvalidArgumentException =
    class 'InvalidArgumentException' : extends(Exception) {
  __init = function(self, argument_index, expected_type, actual_type, level)
    local what = string.format(
        'bad argument #%s (%s expected, got %s)',
        argument_index, expected_type.__name, actual_type)
    Exception.__init(self, what, (level or 1) + 1)
  end,
}
