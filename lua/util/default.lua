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

local function extract(t, ...)
  man(extract, '')
  local result = {}
  for unused, key in ipairs(arg) do
    table.insert(result, t[key])
  end
  return unpack(result)
end

return {
  extract=extract,
  default=default,
}

-- function arguments(argTable, orderedDefaults)
--   local result = {}
--   for unused, keyvalue in ipairs(orderedDefaults) do
--     print('>>', unused .. '/' .. #orderedDefaults)
--     for key, value in pairs(keyvalue) do
--       print('>>', key, value, argTable[key])
--       if type(argTable[key]) == "nil" then
--         table.insert(result, value)
--       else
--         table.insert(result, argTable[key])
--       end
--     end
--   end
--   return unpack(result)
-- end