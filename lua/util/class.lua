local function class(name)
  local class_table = {}
  local class_table_metatable = {}
  class_table.__name = name
  class_table.__extends = {};

  -- Used to initialize an instance of the class.
  function class_table_metatable:__call(...)
    local object = setmetatable(
      class_table.__new and class_table.__new(...) or {},
      class_table)
    if class_table.__init then
      class_table.__init(object, ...)
    end
    return object
  end

  -- If the object doesn't have a field, check the metatable, then any base classes
  function class_table:__defaultindex(key)
    -- Does the class metatable have the field?
    local value = rawget(class_table, key)
    if value then return value end

    -- Do any of the base classes have the field?
    if class_table.__extends then
      for unused, base in ipairs(class_table.__extends) do
        local value = rawget(base, key)
        if value then return value end
      end
    end
  end
  class_table.__index = class_table.__defaultindex

  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local class_definer = {}
  function class_definer:extends(...)
    local arg = {...}
    for i, base in ipairs(arg) do
      class_table.__extends[i] = base
      if base.__name then
        class_table[base.__name] = base
      end
    end
    return class_definer
  end

  local class_definer_metatable = {}
  function class_definer_metatable:__call(metatable)
    for k, v in pairs(metatable) do
      class_table[k] = v
    end
    return class_table
  end

  setmetatable(class_table, class_table_metatable)
  return setmetatable(class_definer, class_definer_metatable)
end

return class
