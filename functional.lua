-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx/core'
local environment = require 'llx/environment'
local list = require 'llx/types/list'
local operators = require 'llx/operators'
local string_module = require 'llx/types/string'
local table_module = require 'llx/types/table'

local _ENV, _M = environment.create_module_environment()

local List = list.List
local String = string_module.String
local Table = table_module.Table
local unpack = table_module.Table.unpack

function range(a, b, c)
  local start = b and a or 1
  local finish = b or a
  local step = c or 1
  local start = start - step
  local index = 0
  local i
  return step > 0 and function()
    i = (i or start) + step
    index = index + 1
    return i < finish and index or nil, i
  end or function()
    i = (i or start) + step
    index = index + 1
    return i > finish and index or nil, i
  end
end

-- Infinite iterators

-- Iterators terminating on the shortest input sequence

-- Combinatoric iterators

local function control_updater(control_holder, new_control, ...)
  control_holder[1] = new_control
  return new_control, ...
end

function generator(iterator, state, control, closing)
  local control_holder = {control}
  local function wrapper()
    return control_updater(control_holder, iterator(state, control_holder[1]))
  end
  return wrapper, nil, nil, closing
end

function map(lambda, ...)
  local sequences = {...}
  local result = List{}
  -- local states = {}
  local controls = {}
  local index = 0
  while true do
    local values = List{}
    local control
    for i, sequence in ipairs(sequences) do
      control, values[i] = sequence(nil --[[ states[i] ]], controls[i])
      if control ~= nil then
        controls[i] = control
      else
        break
      end
    end
    if control == nil then break end
    index = index + 1
    result[index] = lambda(unpack(values))
  end
  return result
end

function even(v) return v % 2 == 0 end

function filter(lambda, sequence)
  lambda = lambda or nonnil
  return function(state, control)
    local v
    repeat
      control, v = sequence(state, control)
    until control == nil or lambda(v)
    return control, v
  end
end

function count(start, step)
  start = start or 1
  step = step or 1
  local value = start - step
  return function()
    value = value + step
    return value
  end
end

function cycle(sequence)
end

function repeat_elem()
end

function accumulate(sequence, lambda, initial_value)
  local result = List{}
  local control
  if initial_value then
    control, result[1] = nil, initial_value
  else
    control, result[1] = sequence()
  end
  for i, v in sequence, nil, control do
    local previous = result[i-1]
    result[i] = lambda(previous, v)
  end
  return result
end

function batched(iterable, n)
  -- Check if n is at least one
  if n < 1 then
    error("n must be at least one")
  end

  -- Create an iterator function
  local control = nil
  local index = 0
  local done = false
  return function()
    if done then return end
    index = index + 1
    local batch = {}
    for i = 1, n do
      local value
      control, value = iterable(nil, control)
      done = (control == nil)
      if done then
        break
      end
      batch[i] = value
    end
    if #batch > 0 then
      return index, batch
    end
  end
end

function chain()
end

function compress()
end

function drop_while()
end

function filterfalse()
end

function group_by()
end

function slice()
end

function pairwise()
end

function star_map()
end

function take_while()
end

function tee()
end

function slice()
end

function zip_longest()
end

function permutations()
end

function combinations()
end

function reduce(sequence, lambda, initial_value)
  local control, result
  if initial_value then
    control, result = nil, initial_value
  else
    control, result = sequence()
  end
  for i, v in sequence, nil, control do
    result = lambda(result, v)
  end
  return result
end

function min(sequence)
  return reduce(sequence, operators.lesser)
end

function max(sequence)
  return reduce(sequence, operators.greater)
end

function sum(sequence)
  return reduce(sequence, operators.add)
end

function product(sequence)
  return reduce(sequence, operators.mul)
end

function zip_impl(iterators, result_handler)
  local control
  return function()
    local result = {}
    for i=1, #iterators do
      local iterator = iterators[i]
      local iterator_control
      iterator_control, result[i] = iterator(nil, control)
      if not iterator_control then
        return
      end
    end
    control = (control or 0) + 1
    return control, result_handler(result)
  end
end

function zip_packed(...)
  return zip_impl({...}, noop)
end

function zip(...)
  return zip_impl({...}, unpack)
end

function cartesian_product(...)
  local sequences = {...}
  local state = {}
  local control = {}
  for i=1, #sequences do
    state[i] = map(noop, sequences[i])
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
          local list = state[i]
          local index = control[i]
          result[i] = list[index]
        end
        return control, unpack(result)
      end
    end
  end, state, control
end

return _M
