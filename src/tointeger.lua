function tointeger(value)
  local __tointeger = getmetafield(value, '__tointeger')
  return __tointeger and __tointeger(value) or math.floor(value)
end