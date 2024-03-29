-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>
require 'llx/src/class'
require 'llx/src/exceptions/exception'
require 'llx/src/flow_control/catch'

ExceptionGroup = class 'ExceptionGroup' : extends(Exception) {
  __init = function(self, exception_list, level)
    local what = ''
    local first = true
    for i, exception in ipairs(exception_list) do
      if not first then what = what .. '\n  ' end
      first = false
      what = what .. exception.what 
    end
    Exception.__init(self, what, (level or 1) + 1)
    self.exception_list = exception_list
  end,

  -- multicatch = function(self, try_block)
  --   Table(try_block)
  --   if #try_block > 0 then
  --     local exception_list = self.exception_list
  --     for _, thrown_exception in ipairs(exception_list) do
  --       find_and_handle_exception(try_block, thrown_exception)
  --     end
  --   end
  -- end,

  __tostring = Exception.__tostring,
}
