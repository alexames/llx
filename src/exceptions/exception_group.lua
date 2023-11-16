-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>
require 'llx/src/class'
require 'llx/src/exceptions/exception'
require 'llx/src/flow_control/catch'

ExceptionGroup =
    class 'ExceptionGroup' : extends(Exception) {
  __init = function(self, exception_list, level)
    local prologue =
      string.format('encountered %s exceptions:\n', #exception_list)
    local epilogue = '\nexceptions gathered at:'
    local what = Table.concat(exception_list, '\n')
    Exception.__init(self, prologue .. what .. epilogue, (level or 1) + 1)
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

  __tostring = function(self)
    return self.what
  end,
}
