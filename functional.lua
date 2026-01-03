-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'
local list = require 'llx.types.list'
local operators = require 'llx.operators'
local string_module = require 'llx.types.string'
local table_module = require 'llx.types.table'

local _ENV, _M = environment.create_module_environment()

local List = list.List
local String = string_module.String
local Table = table_module.Table
local unpack = table_module.Table.unpack
local nonnil = core.nonnil
local noop = core.noop

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
  -- Cache the sequence into a list for cycling
  local cache = List{}
  local control = nil
  for i, v in sequence do
    cache:insert(v)
  end
  
  if #cache == 0 then
    return function() return nil end
  end
  
  local index = 0
  return function()
    index = (index % #cache) + 1
    return index, cache[index]
  end
end

function repeat_elem(element, times)
  if times == nil then
    -- Infinite repeat
    return function()
      return 1, element
    end
  else
    local count = 0
    return function()
      if count < times then
        count = count + 1
        return count, element
      end
      return nil
    end
  end
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

function chain(...)
  local sequences = {...}
  local current_seq_index = 1
  local current_control = nil
  
  return function()
    while current_seq_index <= #sequences do
      local sequence = sequences[current_seq_index]
      local control, value = sequence(nil, current_control)
      
      if control ~= nil then
        current_control = control
        return control, value
      else
        -- Move to next sequence
        current_seq_index = current_seq_index + 1
        current_control = nil
      end
    end
    return nil
  end
end

function compress(sequence, selectors)
  -- selectors is a sequence of boolean values
  return function(state, control)
    local selector_control = nil
    while true do
      local seq_control, value = sequence(state, control)
      if seq_control == nil then
        return nil
      end
      
      local sel_control, selector = selectors(nil, selector_control)
      if sel_control == nil then
        return nil
      end
      
      control = seq_control
      selector_control = sel_control
      
      if selector then
        return control, value
      end
    end
  end
end

function drop_while(predicate, sequence)
  local dropped = false
  return function(state, control)
    if not dropped then
      -- Drop elements until predicate is false
      local temp_control = control
      while true do
        local ctrl, value = sequence(state, temp_control)
        if ctrl == nil then
          return nil
        end
        if not predicate(value) then
          dropped = true
          control = ctrl
          return control, value
        end
        temp_control = ctrl
      end
    else
      -- Pass through remaining elements
      return sequence(state, control)
    end
  end
end

function filterfalse(predicate, sequence)
  predicate = predicate or nonnil
  return filter(function(v) return not predicate(v) end, sequence)
end

function group_by(sequence, key_func)
  key_func = key_func or noop
  local groups = {}
  local group_keys = {}
  
  -- First pass: collect all elements
  for i, v in sequence do
    local key = key_func(v)
    if not groups[key] then
      groups[key] = List{}
      table.insert(group_keys, key)
    end
    groups[key]:insert(v)
  end
  
  -- Return iterator over groups
  local index = 0
  return function()
    index = index + 1
    if index <= #group_keys then
      local key = group_keys[index]
      return key, groups[key]
    end
    return nil
  end
end

function slice(sequence, start, stop, step)
  start = start or 1
  step = step or 1
  local index = 0
  local current_control = nil
  
  -- Skip to start
  local skipped = 0
  while skipped < start - 1 do
    local ctrl, _ = sequence(nil, current_control)
    if ctrl == nil then
      return function() return nil end
    end
    current_control = ctrl
    skipped = skipped + 1
  end
  
  return function()
    if stop and index >= stop - start then
      return nil
    end
    
    local ctrl, value = sequence(nil, current_control)
    if ctrl == nil then
      return nil
    end
    
    -- Apply step
    if step > 1 then
      for i = 1, step - 1 do
        ctrl, _ = sequence(nil, ctrl)
        if ctrl == nil then
          return nil
        end
      end
    end
    
    current_control = ctrl
    index = index + 1
    return index, value
  end
end

function pairwise(sequence)
  local prev_control = nil
  local prev_value = nil
  local first = true
  
  return function(state, control)
    if first then
      local ctrl, value = sequence(state, control)
      if ctrl == nil then
        return nil
      end
      prev_control = ctrl
      prev_value = value
      first = false
    end
    
    local ctrl, value = sequence(state, prev_control)
    if ctrl == nil then
      return nil
    end
    
    local result = {prev_value, value}
    prev_control = ctrl
    prev_value = value
    return ctrl, unpack(result)
  end
end

function star_map(lambda, ...)
  local sequences = {...}
  return function()
    local values = {}
    for i, seq in ipairs(sequences) do
      local ctrl, val = seq()
      if ctrl == nil then
        return nil
      end
      values[i] = val
    end
    return lambda(unpack(values))
  end
end

function take_while(predicate, sequence)
  local done = false
  return function(state, control)
    if done then
      return nil
    end
    
    local ctrl, value = sequence(state, control)
    if ctrl == nil then
      done = true
      return nil
    end
    
    if predicate(value) then
      return ctrl, value
    else
      done = true
      return nil
    end
  end
end

function tee(sequence, n)
  n = n or 2
  local cache = List{}
  local iterators = {}
  local indices = {}
  
  -- Initialize iterators
  for i = 1, n do
    indices[i] = 0
    iterators[i] = function()
      indices[i] = indices[i] + 1
      if indices[i] <= #cache then
        return indices[i], cache[indices[i]]
      else
        -- Need to fetch more from sequence
        local ctrl, value = sequence()
        if ctrl == nil then
          return nil
        end
        cache:insert(value)
        return indices[i], value
      end
    end
  end
  
  return unpack(iterators)
end

function zip_longest(...)
  local sequences = {...}
  local fillvalue = nil
  if #sequences > 0 and type(sequences[#sequences]) ~= 'function' then
    fillvalue = sequences[#sequences]
    sequences = {table.unpack(sequences, 1, #sequences - 1)}
  end
  
  local controls = {}
  local done = {}
  
  return function()
    local result = {}
    local all_done = true
    
    for i = 1, #sequences do
      if not done[i] then
        local ctrl, value = sequences[i](nil, controls[i])
        if ctrl ~= nil then
          controls[i] = ctrl
          result[i] = value
          all_done = false
        else
          done[i] = true
          result[i] = fillvalue
        end
      else
        result[i] = fillvalue
      end
    end
    
    if all_done then
      return nil
    end
    
    return unpack(result)
  end
end

function permutations(sequence, r)
  -- Convert sequence to list
  local elements = List{}
  for i, v in sequence do
    elements:insert(v)
  end
  
  r = r or #elements
  if r > #elements then
    return function() return nil end
  end
  
  -- Generate permutations using recursive approach
  local indices = {}
  for i = 1, r do
    indices[i] = i
  end
  
  local function next_permutation()
    -- Find the rightmost element that is smaller than the element after it
    local i = r - 1
    while i >= 1 and indices[i] >= indices[i + 1] do
      i = i - 1
    end
    
    if i < 1 then
      return false
    end
    
    -- Find the rightmost element greater than indices[i]
    local j = r
    while indices[j] <= indices[i] do
      j = j - 1
    end
    
    -- Swap
    indices[i], indices[j] = indices[j], indices[i]
    
    -- Reverse the suffix
    local left = i + 1
    local right = r
    while left < right do
      indices[left], indices[right] = indices[right], indices[left]
      left = left + 1
      right = right - 1
    end
    
    return true
  end
  
  local first = true
  return function()
    if first then
      first = false
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return unpack(result)
    end
    
    if next_permutation() then
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return unpack(result)
    end
    
    return nil
  end
end

function combinations(sequence, r)
  -- Convert sequence to list
  local elements = List{}
  for i, v in sequence do
    elements:insert(v)
  end
  
  if r > #elements then
    return function() return nil end
  end
  
  -- Generate combinations using recursive approach
  local indices = {}
  for i = 1, r do
    indices[i] = i
  end
  
  local function next_combination()
    -- Find the rightmost index that can be incremented
    local i = r
    while i >= 1 and indices[i] == #elements - r + i do
      i = i - 1
    end
    
    if i < 1 then
      return false
    end
    
    -- Increment and reset subsequent indices
    indices[i] = indices[i] + 1
    for j = i + 1, r do
      indices[j] = indices[j - 1] + 1
    end
    
    return true
  end
  
  local first = true
  return function()
    if first then
      first = false
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return unpack(result)
    end
    
    if next_combination() then
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return unpack(result)
    end
    
    return nil
  end
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
