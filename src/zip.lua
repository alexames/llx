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