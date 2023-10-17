function extract(t, ...)
  local result = {}
  for _, k in ipairs({...}) do
    table.insert(result, t[k])
  end
  return table.unpack(result)
end
