Table = table
Table.__name = 'Table';

Table.isinstance = function(v)
  return type(v) == 'table'
end

local table_instance_metatable = {
  __index = Table
}

local table_metatable = {
  __call = function(self, t)
    return setmetatable(t or {}, table_instance_metatable)
  end
}

function Table.__tostring() return 'Table' end;

setmetatable(table, table_metatable)

function Table:remove_if(predicate)
  local j = 1
  local size = #self;
  for i=1, size do
    if not predicate(self[i]) then
      if (i ~= j) then
        self[j] = self[i]
        self[i] = nil
      end
      j = j + 1
    else
      self[i] = nil
    end
  end
  return self;
end

function Table:get_or_insert_lazy(k, default_func)
  local v = self[k]
  if not v then
    v = default_func()
    self[k] = v
  end
  return v
end

function Table:get_or_insert(k, default) 
  local v = self[k]
  if not v then
    v = default
    self[k] = v
  end
  return v
end

function Table:copy(destination)
  destination = destination or {}
  for k, v in pairs(self) do
    destination[k] = v
  end
  return destination
end

function Table:deepcopy(destination)
  -- todo
end

function Table:apply(xform)
  for k, v in pairs(self) do
    self[k] = xform(v)
  end
end

function Table:find(value)
  for k, v in pairs(self) do
    if v == value then
      return k, v
    end
  end
end

function Table:find_if(predicate)
  for k, v in pairs(self) do
    if predicate(k, v) then
      return k, v
    end
  end
end

function Table:ifind(value, init)
  for i=init or 1, #self do
    if self[i] == value then
      return i, v
    end
  end
end

function Table:ifind_if(predicate, init)
  for i=init or 1, #self do
    if predicate(i, self[i]) then
      return i, self[i]
    end
  end
end

function Table:insert_unique(value)
  if not self:ifind(value) then
    self:insert(value)
  end
end

return Table
