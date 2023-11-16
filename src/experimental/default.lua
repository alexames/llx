-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local function default(defaultsTable, argTable)
  return setmetatable({}, {
    __index = function(key)
      if type(argTable[key]) ~= "nil" then
        return argTable[key]
      else
        return defaultsTable[key]
      end
    end
  })
end

return default
