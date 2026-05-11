-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local function copy_into(target_module, k, v)
  assert(target_module[k] == nil,
         string.format('Value %s has multiple definitions', k))
  target_module[k] = v
end

local function submodule_flattener(submodules)
  local module = {}
  for name_or_index, submodule in pairs(submodules) do
    if type(name_or_index) == 'number' then
      if type(submodule) == 'table' then
        -- Positional submodule: flatten its public surface into
        -- the parent.
        for key, value in pairs(submodule) do
          copy_into(module, key, value)
        end
      end
      -- Non-table at a numeric index is silently ignored. The
      -- common cause is `require`'s second return value (the
      -- source file path) leaking into the table constructor
      -- when the last positional entry is a `require` call.
    else
      copy_into(module, name_or_index, submodule)
    end
  end

  return setmetatable({}, environment.make_module_metatable(module))
end

return submodule_flattener
