-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local compat = require 'llx.compat'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

function trace(...)
  local info = debug.getinfo(2, "Sln")
  io.write(compat.format('%s:%s', info.source:sub(2), info.currentline))
  if info.name then
    io.write(compat.format(':%s', info.name))
  end
  if #{...} > 0 then
    io.write(' ')
  end
  print(...)
  return ...
end

return _M
