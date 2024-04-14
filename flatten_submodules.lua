-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

local function copy_into(target_module, k, v)
  assert(target_module[k] == nil,
         string.format('Value %s has multiple definitions', k))
  target_module[k] = v
end

local function submodule_flattener(submodules)
  local module = {}
  local len = #submodules
  for name_or_index, submodule in pairs(submodules) do
    if type(name_or_index) == 'number'
       and type(submodule) == 'table'
       and name_or_index >= 1
       and name_or_index <= len then
      for key, value in pairs(submodule) do
        copy_into(module, key, value)
      end
    else
      copy_into(module, name_or_index, submodule)
    end
  end

  return setmetatable({}, environment.make_module_metatable(module))
end

return submodule_flattener
