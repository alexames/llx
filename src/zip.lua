-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

--- Zip multiple iterators to be iterated together.
--
-- Given some number of table-wrapped iterators, this will create a wrapper
-- around those iterators, and each time the wrapper is called it will place the
-- results of each of the given iterators into a table that will all be returned
-- together. If any of the given iterators returns nil for its control value,
-- then iteration is concluded and the whole thing returns nil.
--
-- Sample use case:
-- ```
-- t1 = {1, 2, 3, 4}
-- t2 = {'a', 'b', 'c'}
-- t3 = {z=100, y=200, x=300}
--
-- for a, b, c in zip({ipairs(t1)}, {ipairs(t2)}, {pairs(t3)}) do
--   local fmt = '%s: key=%s, value=%s'
--   print(fmt:format('a', a[1], a[2]))
--   print(fmt:format('b', b[1], b[2]))
--   print(fmt:format('c', c[1], c[2]))
-- end
-- ```
--
-- This will print:
-- ```
-- a: key=1, value=1
-- b: key=1, value=a
-- c: key=x, value=300
--
-- a: key=2, value=2
-- b: key=2, value=b
-- c: key=z, value=100
--
-- a: key=3, value=3
-- b: key=3, value=c
-- c: key=y, value=200
-- ```
-- @return An iterator function that returns the value of each of the wrapped
--         iterators on each call.
function zip(...)
  local iterators = {...}
  for i = 1, #iterators do
    local iterator = iterators[i]
    assert(type(iterator) == "table",
          "you have to wrap the iterators in a table")
  end
  return function()
    local results = {}
    for i=1, #iterators do
      local iterator = iterators[i]
      local iteration_function, state, control = iterator[1], iterator[2], iterator[3]
      local iteration_results = {iteration_function(state, control)}
      control = iteration_results[1]
      if control == nil then return nil end
      iterator[3] = control
      results[i] = iteration_results
    end
    return table.unpack(results)
  end
end

return zip
