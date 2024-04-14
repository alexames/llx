-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

Thread = {}

Thread.__name = 'Thread'

function Thread:__isinstance(v)
  return type(v) == 'thread'
end

local metatable = {}

function metatable:__tostring()
  return 'Thread'
end

setmetatable(Thread, metatable)

return _M
