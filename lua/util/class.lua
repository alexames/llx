local function class(name)
  local classTable = {}
  local classTableMetatable = {}
  classTable.__name = name
  classTable.__extends = {};

  -- Used to initialize an instance of the class.
  function classTableMetatable:__call(...)
    local object = setmetatable(
      classTable.__new and classTable.__new(...) or {},
      classTable)
    if classTable.__init then
      classTable.__init(object, ...)
    end
    return object
  end

  -- If the object doesn't have a field, check the metatable, then any base classes
  function classTable:__defaultindex(key)
    -- Does the class metatable have the field?
    local value = rawget(classTable, key)
    if value then return value end

    -- Do any of the base classes have the field?
    if classTable.__extends then
      for unused, base in ipairs(classTable.__extends) do
        local value = rawget(base, key)
        if value then return value end
      end
    end
  end
  classTable.__index = classTable.__defaultindex

  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local classDefiner = {}
  function classDefiner:extends(...)
    local arg = {...}
    for i, base in ipairs(arg) do
      classTable.__extends[i] = base
      if base.__name then
        classTable[base.__name] = base
      end
    end
    return classDefiner
  end

  local classDefinerMetatable = {}
  function classDefinerMetatable:__call(metatable)
    for k, v in pairs(metatable) do
      classTable[k] = v
    end
    return classTable
  end

  setmetatable(classTable, classTableMetatable)
  return setmetatable(classDefiner, classDefinerMetatable)
end

return class
