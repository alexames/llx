-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/core'
require 'llx/src/operators'
require 'llx/src/types/list'
require 'llx/src/types/table'

local unpack = Table.unpack

function transform(sequence, lambda)
  local result = List{}
  for i, v in sequence do
    result[i] = lambda(sequence[i])
  end
  return result
end

function reduce(sequence, lambda, initial_value)
  local control, result
  if initial_value then
    control, result = nil, initial_value
  else
    control, result = sequence(nil, nil)
  end
  for i, v in sequence, nil, control do
    result = lambda(result, v)
  end
  return result
end

function min(sequence)
  return reduce(sequence, lesser)
end

function max(sequence)
  return reduce(sequence, greater)
end

function sum(sequence)
  return reduce(sequence, add)
end

function product(sequence)
  return reduce(sequence, mul)
end

function zip_impl(iterators, result_handler)
  return function(state, control)
    control = (control or 0) + 1
    local result = {}
    for i=1, #iterators do
      local iterator = iterators[i]
      iterator_control, result[i] = iterator(nil, control)
      if not iterator_control then
        return
      end
    end
    return control, result_handler(result)
  end
end

function zip(...)
  return zip_impl({...}, unpack)
end

function zip_together(...)
  return zip_impl({...}, noop)
end

function cartesian_product(...)
  local sequences = {...}
  local state = {}
  local control = {}
  for i=1, #sequences do
    state[i] = transform(sequences[i], noop)
    control[i] = 1
  end
  control[#control] = 0
  return function(state, control)
    for i=#control, 1, -1 do
      control[i] = control[i] + 1
      if control[i] > #state[i] then
        control[i] = 1
      else
        local result = {}
        for i=1, #state do
          result[i] = state[i][control[i]]
        end
        return control, unpack(result)
      end
    end
  end, state, control
end
