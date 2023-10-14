local function table_is_list(t)
  local count = 0
  for k, unused in pairs(t) do
    if type(k) ~= 'number' then return false end
    count = count + 1
  end
  return count == #t
end

local function dump_value(t, visited)
  local result = ""
  visited = visited or {}
  if type(t) == 'table' then
    if visited[t] then
      result = result .. tostring(t)
    else
      visited[t] = true
      result = result .. '{'
      local first = true

      local isList = table_is_list(t)
      for k, v in pairs(t) do
        if first then
          first = false
        else
          result = result .. ','
        end
        if type(k) == 'string' then
          result = result .. k .. '='
        elseif type(k) == 'number' then
          if not isList then
            result = result .. '[' .. k .. ']='
          end
        end
        result = result .. dump_value(v, visited)
      end
      result = result .. '}'
    end
  elseif type(t) == "string" then
    result = result .. "'" .. t .. "'"
  else
    result = result .. tostring(t)
  end
  return result
end

return dump_value