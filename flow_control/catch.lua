-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

local _ENV, _M = environment.create_module_environment()

function catch(exception, handler)
  return {exception=exception, handler=handler}
end

return _M
