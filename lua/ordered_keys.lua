
function ordered_keys()
  local keys = {}
  local i = 0
  return function(key)
    i = i + 1
    keys[i]=key
    return key
  end, function(t)
    local i = 0
    return function(t, k)
      i = i + 1
      local k = keys[i]
      return k, t[k]
    end, t, nil
  end
end

return ordered_keys