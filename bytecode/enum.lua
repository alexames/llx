
local enum_metatable = {
  insert = function(self, k, v)
    local enum_object = {name=v, value=k}
    if self[k] == nil then
      rawset(self, k, enum_object)
    end
    if self[v] == nil then
      rawset(self, v, enum_object)
    end
  end,

  __newindex = function(self, k, v)
    self:insert(k, v)
  end
}

enum_metatable.__index = enum_metatable

local function enum(t)
  local result = setmetatable({}, enum_metatable)
  for k, v in pairs(t) do
    result[k] = v
  end
  return result
end

return {
  enum = enum
}