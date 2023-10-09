setmetatable(_G, {
  __newindex = function(t, k, v)
    error 'global writes disallowed'
  end
})
