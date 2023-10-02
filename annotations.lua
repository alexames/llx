
local docstrings = {}
local next_docstring = nil
function docstring(s)
  next_docstring = s
end
function man(fn)
  return docstrings[fn]
end

setmetatable(_G, {
  __newindex = function(t, k, v)
    if next_docstring then
      docstrings[v] = next_docstring
      next_docstring = nil
    end
    rawset(t, k, v)
  end
})

--------------------------------------------------------------------------------
-- Usage:

docstring[[Brief oneline description.

  Arguments:
    * Blah blah blah

  Returns: a foo bar that blahs
]]
function Test()
  print('Test called!')
end

docstring[[Brief oneline description.

  Description of this value
]]
pi = 3.1

print(man(Test))
print(man(pi))