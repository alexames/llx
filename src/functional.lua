-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/operators'

function transform(list, lambda)
  local result = List{}
  for i=1, #list do
    result[i] = lambda(list[i])
  end
  return result
end

function reduce(list, lambda, initial_value)
  local result = initial_value or list[1]
  for i=initial_value and 1 or 2, #list do
    result = lambda(result, list[i])
  end
  return result
end

function min(list)
  return reduce(list, lesser)
end

function max(list)
  return reduce(list, greater)
end

function sum(list)
  return reduce(list, add)
end

function product(list)
  return reduce(list, mul)
end