-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

setmetatable(_G, {
  __newindex = function(t, k, v)
    error 'global writes disallowed'
  end
})
