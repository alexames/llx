-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

function trace(...)
  local info = debug.getinfo(2, "Sln")
  io.write(string.format('%s:%s', info.source:sub(2), info.currentline))
  if info.name then
    io.write(string.format(':%s', info.name))
  end
  if #{...} > 0 then
    io.write(' ')
  end
  print(...)
  return ...
end

return _M
