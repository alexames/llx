-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

function p(...)
  print(...)
  return ...
end

function printtable(t)
  for k, v in pairs(t) do print(k, v) end
end

function printlist(t)
  for i, v in ipairs(t) do print(i, v) end
end

return _M
