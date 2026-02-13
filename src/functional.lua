-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- Functional programming utilities inspired by Python's itertools.
-- Provides iterator-based operations for mapping, filtering, reducing,
-- and combining sequences. Many functions are inspired by Python's
-- itertools module.
-- @module llx.functional

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

--- Creates an iterator over a range of numbers.
-- Similar to Python's range() function. Can be called
-- with 1, 2, or 3 arguments.
-- @param a If only argument: end value (start=1). If 2+ arguments: start value.
-- @param b End value (exclusive)
-- @param c Step value (default: 1). Can be negative for descending ranges.
-- @return Iterator function yielding (index, value) pairs
-- @usage
-- for i, v in range(5) do print(v) end        -- 1, 2, 3, 4
-- for i, v in range(2, 5) do print(v) end     -- 2, 3, 4
-- for i, v in range(1, 10, 2) do print(v) end -- 1, 3, 5, 7, 9
function range(a, b, c)
  local start = b and a or 1
  local finish = b or a
  local step = c or 1
  if step == 0 then
    error("range() step argument must not be zero", 2)
  end
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

--- Creates an inclusive range iterator.
-- Like range but includes the end value.
-- @param a If only argument: end value (start=1). If 2+ arguments: start value.
-- @param b End value (inclusive)
-- @param c Step value (default: 1)
-- @return Iterator function yielding (index, value) pairs
function range_inclusive(a, b, c)
  local start = b and a or 1
  local finish = b or a
  local step = c or 1
  if step == 0 then
    error("range_inclusive() step argument must not be zero", 2)
  end
  local start = start - step
  local index = 0
  local i
  return step > 0 and function()
    i = (i or start) + step
    index = index + 1
    return i <= finish and index or nil, i
  end or function()
    i = (i or start) + step
    index = index + 1
    return i >= finish and index or nil, i
  end
end

-- Internal helper for control state management
local function control_updater(control_holder, new_control, ...)
  control_holder[1] = new_control
  return new_control, ...
end

--- Wraps an iterator into a stateless generator.
-- Converts a stateful iterator into a form suitable for use in for loops.
-- @param iterator The iterator function
-- @param state The initial state
-- @param control The initial control value
-- @param closing Optional closing value for to-be-closed variables
-- @return Wrapped iterator, nil, nil, closing
function generator(iterator, state, control, closing)
  local control_holder = {control}
  local function wrapper()
    return control_updater(control_holder, iterator(state, control_holder[1]))
  end
  return wrapper, nil, nil, closing
end

--- Maps a function over one or more sequences.
-- Applies a transformation function to elements from one or more sequences,
-- returning a List of results. Stops when any sequence is exhausted.
-- @param lambda The transformation function
-- @param ... One or more iterator/sequence arguments
-- @return List of transformed values
-- @usage
-- local doubled = map(function(x) return x * 2 end, range(5))
-- -- Returns List{2, 4, 6, 8}
function map(lambda, ...)
  local sequences = {...}
  local result = List{}
  local controls = {}
  local index = 0
  while true do
    local values = List{}
    local control
    for i, sequence in ipairs(sequences) do
      control, values[i] = sequence(nil, controls[i])
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

--- Filters a sequence based on a predicate function.
-- Returns an iterator that yields only elements for which the predicate
-- returns true.
-- @param lambda Predicate function (default: nonnil)
-- @param sequence The input sequence/iterator
-- @return Iterator yielding filtered elements
-- @usage
-- for i, v in filter(function(x) return x > 3 end, range(10)) do
--   print(v)  -- 4, 5, 6, 7, 8, 9
-- end
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

--- Creates an infinite counter iterator.
-- Yields numbers starting from start, incrementing by step each time.
-- @param start Starting value (default: 1)
-- @param step Increment value (default: 1)
-- @return Iterator function
-- @usage
-- local counter = count(10, 5)
-- print(counter())  -- 10
-- print(counter())  -- 15
-- print(counter())  -- 20
function count(start, step)
  start = start or 1
  step = step or 1
  local value = start - step
  return function()
    value = value + step
    return value
  end
end

--- Creates an iterator that cycles through a sequence infinitely.
-- Caches the sequence and repeats it forever.
-- @param sequence The input sequence
-- @return Iterator that cycles through elements
-- @usage
-- local cycled = cycle(List{1, 2, 3})
-- -- yields 1, 2, 3, 1, 2, 3, 1, 2, 3, ...
function cycle(sequence)
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

--- Creates an iterator that repeats an element.
-- If times is nil, repeats infinitely. Otherwise, repeats exactly times times.
-- @param element The element to repeat
-- @param times Number of repetitions (nil for infinite)
-- @return Iterator function
-- @usage
-- for i, v in repeat_elem('x', 3) do print(v) end  -- x, x, x
function repeat_elem(element, times)
  if times == nil then
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

--- Creates a running accumulation of values.
-- Like reduce, but returns all intermediate results.
-- @param sequence The input sequence
-- @param lambda Accumulator function (accumulator, value) -> new_accumulator
-- @param initial_value Optional initial value
-- @return List of accumulated values
-- @usage
-- local sums = accumulate(range(5), function(a, b) return a + b end)
-- -- Returns List{1, 3, 6, 10}
function accumulate(sequence, lambda, initial_value)
  local result = List{}
  local index = 0
  local previous

  if initial_value ~= nil then
    index = 1
    result[1] = initial_value
    previous = initial_value
  else
    local ctrl, first = sequence()
    if ctrl == nil then return result end
    index = 1
    result[1] = first
    previous = first
  end

  for _, v in sequence, nil, initial_value and nil or 1 do
    index = index + 1
    previous = lambda(previous, v)
    result[index] = previous
  end
  return result
end

--- Batches elements from a sequence into groups of n.
-- Returns an iterator that yields batches (tables) of n elements.
-- The last batch may have fewer than n elements.
-- @param iterable The input sequence
-- @param n Batch size (must be >= 1)
-- @return Iterator yielding (index, batch) pairs
-- @usage
-- for i, batch in batched(range(10), 3) do
--   print(table.concat(batch, ', '))  -- "1, 2, 3", "4, 5, 6", ...
-- end
function batched(iterable, n)
  if n < 1 then
    error("n must be at least one")
  end

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

--- Chains multiple sequences together.
-- Creates an iterator that yields elements from the first sequence,
-- then the second, and so on.
-- @param ... Multiple sequences to chain
-- @return Iterator over all sequences
-- @usage
-- for i, v in chain(List{1, 2}, List{3, 4}) do
--   print(v)  -- 1, 2, 3, 4
-- end
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
        current_seq_index = current_seq_index + 1
        current_control = nil
      end
    end
    return nil
  end
end

--- Filters a sequence based on a parallel sequence of boolean selectors.
-- Returns elements where the corresponding selector is true.
-- @param sequence The input sequence
-- @param selectors Iterator of boolean values
-- @return Iterator yielding selected elements
-- @usage
-- local data = List{1, 2, 3, 4, 5}
-- local mask = List{true, false, true, false, true}
-- for i, v in compress(data, mask) do print(v) end  -- 1, 3, 5
function compress(sequence, selectors)
  local selector_control = nil
  return function(state, control)
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

--- Drops elements while predicate is true, then yields the rest.
-- Once an element fails the predicate, all remaining elements are yielded.
-- @param predicate Function to test elements
-- @param sequence The input sequence
-- @return Iterator over remaining elements
-- @usage
-- for i, v in drop_while(function(x) return x < 5 end, range(10)) do
--   print(v)  -- 5, 6, 7, 8, 9
-- end
function drop_while(predicate, sequence)
  local dropped = false
  return function(state, control)
    if not dropped then
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
      return sequence(state, control)
    end
  end
end

--- Filters elements where predicate is false.
-- The opposite of filter - keeps elements that fail the predicate.
-- @param predicate Function to test elements (default: nonnil)
-- @param sequence The input sequence
-- @return Iterator yielding elements where predicate is false
function filterfalse(predicate, sequence)
  predicate = predicate or nonnil
  return filter(function(v) return not predicate(v) end, sequence)
end

--- Groups elements by a key function.
-- Collects all elements and groups them by the key returned by key_func.
-- @param sequence The input sequence
-- @param key_func Function to compute group key (default: identity)
-- @return Iterator yielding (key, List of values) pairs
-- @usage
-- for key, values in group_by(range(10), function(x) return x % 3 end) do
--   print(key, values)
-- end
function group_by(sequence, key_func)
  key_func = key_func or noop
  local groups = {}
  local group_keys = {}

  for i, v in sequence do
    local key = key_func(v)
    if not groups[key] then
      groups[key] = List{}
      table.insert(group_keys, key)
    end
    groups[key]:insert(v)
  end

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

--- Slices a sequence with start, stop, and step.
-- Similar to Python's slice notation.
-- @param sequence The input sequence
-- @param start Starting index (default: 1)
-- @param stop Stopping index (exclusive)
-- @param step Step size (default: 1)
-- @return Iterator over the slice
-- @usage
-- for i, v in slice(range(20), 5, 15, 2) do
--   print(v)  -- every other element from 5 to 14
-- end
function slice(sequence, start, stop, step)
  start = start or 1
  step = step or 1
  local index = 0
  local current_control = nil

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

--- Returns consecutive pairs of elements.
-- For sequence [a, b, c, d], yields (a, b), (b, c), (c, d).
-- @param sequence The input sequence
-- @return Iterator yielding (control, prev, current) tuples
-- @usage
-- for i, a, b in pairwise(List{1, 2, 3, 4}) do
--   print(a, b)  -- (1, 2), (2, 3), (3, 4)
-- end
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

--- Maps a function over parallel sequences, unpacking arguments.
-- Each iteration unpacks values from all sequences as separate arguments.
-- @param lambda Function to apply
-- @param ... Multiple sequences
-- @return Iterator function
function star_map(lambda, ...)
  local sequences = {...}
  local controls = {}
  return function()
    local values = {}
    for i, seq in ipairs(sequences) do
      local ctrl, val = seq(nil, controls[i])
      if ctrl == nil then
        return nil
      end
      controls[i] = ctrl
      values[i] = val
    end
    return lambda(unpack(values))
  end
end

--- Takes elements while predicate is true, then stops.
-- Once an element fails the predicate, iteration ends.
-- @param predicate Function to test elements
-- @param sequence The input sequence
-- @return Iterator
-- @usage
-- for i, v in take_while(function(x) return x < 5 end, range(10)) do
--   print(v)  -- 1, 2, 3, 4
-- end
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

--- Creates n independent iterators from a single sequence.
-- Each iterator can be advanced independently.
-- @param sequence The input sequence
-- @param n Number of iterators to create (default: 2)
-- @return n iterator functions
-- @usage
-- local it1, it2 = tee(range(5), 2)
-- print(it1())  -- 1
-- print(it2())  -- 1 (independent)
function tee(sequence, n)
  n = n or 2
  local cache = List{}
  local iterators = {}
  local indices = {}
  local seq_control = nil

  for i = 1, n do
    indices[i] = 0
    iterators[i] = function()
      indices[i] = indices[i] + 1
      if indices[i] <= #cache then
        return indices[i], cache[indices[i]]
      else
        local ctrl, value = sequence(nil, seq_control)
        if ctrl == nil then
          return nil
        end
        seq_control = ctrl
        cache:insert(value)
        return indices[i], value
      end
    end
  end

  return unpack(iterators)
end

--- Zips sequences together, filling missing values with fillvalue.
-- Unlike zip, continues until ALL sequences are exhausted.
-- @param ... Multiple sequences, optionally ending with a fillvalue
-- @return Iterator over tuples
-- @usage
-- for a, b in zip_longest(List{1, 2, 3}, List{4, 5}, 0) do
--   print(a, b)  -- (1, 4), (2, 5), (3, 0)
-- end
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

--- Generates all permutations of a sequence.
-- Returns an iterator yielding r-length permutations.
-- @param sequence The input sequence
-- @param r Length of permutations (default: length of sequence)
-- @return Iterator over permutations
-- @usage
-- for a, b in permutations(List{1, 2, 3}, 2) do
--   print(a, b)  -- (1, 2), (1, 3), (2, 1), (2, 3), (3, 1), (3, 2)
-- end
function permutations(sequence, r)
  local elements = List{}
  for i, v in sequence do
    elements:insert(v)
  end

  local n = #elements
  r = r or n
  if r > n then
    return function() return nil end
  end

  local indices = {}
  for i = 1, n do
    indices[i] = i
  end

  local cycles = {}
  for i = 1, r do
    cycles[i] = n - i + 1
  end

  local first = true
  local done = false
  local index = 0

  return function()
    if done then
      return nil
    end

    if first then
      first = false
      index = index + 1
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return index, unpack(result)
    end

    local i = r
    while i >= 1 do
      cycles[i] = cycles[i] - 1
      if cycles[i] == 0 then
        local temp = indices[i]
        for j = i, n - 1 do
          indices[j] = indices[j + 1]
        end
        indices[n] = temp
        cycles[i] = n - i + 1
        i = i - 1
      else
        local j = n - cycles[i] + 1
        indices[i], indices[j] = indices[j], indices[i]
        index = index + 1
        local result = {}
        for k = 1, r do
          result[k] = elements[indices[k]]
        end
        return index, unpack(result)
      end
    end

    done = true
    return nil
  end
end

--- Generates all combinations of a sequence.
-- Returns an iterator yielding r-length combinations (without repetition).
-- @param sequence The input sequence
-- @param r Length of combinations
-- @return Iterator over combinations
-- @usage
-- for a, b in combinations(List{1, 2, 3}, 2) do
--   print(a, b)  -- (1, 2), (1, 3), (2, 3)
-- end
function combinations(sequence, r)
  local elements = List{}
  for i, v in sequence do
    elements:insert(v)
  end

  local n = #elements
  if r > n then
    return function() return nil end
  end

  local indices = {}
  for i = 1, r do
    indices[i] = i
  end

  local function next_combination()
    local i = r
    while i >= 1 and indices[i] == n - r + i do
      i = i - 1
    end

    if i < 1 then
      return false
    end

    indices[i] = indices[i] + 1
    for j = i + 1, r do
      indices[j] = indices[j - 1] + 1
    end

    return true
  end

  local first = true
  local index = 0
  return function()
    if first then
      first = false
      index = index + 1
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return index, unpack(result)
    end

    if next_combination() then
      index = index + 1
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return index, unpack(result)
    end

    return nil
  end
end

--- Reduces a sequence to a single value using a binary function.
-- @param sequence The input sequence
-- @param lambda Binary function (accumulator, value) -> new_accumulator
-- @param initial_value Optional initial value for the accumulator
-- @return The final accumulated value
-- @usage
-- local sum = reduce(range(5), function(a, b) return a + b end)  -- 10
function reduce(sequence, lambda, initial_value)
  local control, result
  if initial_value ~= nil then
    control, result = nil, initial_value
  else
    control, result = sequence()
  end
  for i, v in sequence, nil, control do
    result = lambda(result, v)
  end
  return result
end

--- Returns the minimum element of a sequence.
-- Stable: returns the first minimum element among equivalent values.
-- @param sequence The input sequence
-- @return The minimum value
function min(sequence)
  return reduce(sequence, function(a, b) return b < a and b or a end)
end

--- Returns the maximum element of a sequence.
-- Stable: returns the last maximum element among equivalent values.
-- @param sequence The input sequence
-- @return The maximum value
function max(sequence)
  return reduce(sequence, function(a, b) return a > b and a or b end)
end

--- Returns the sum of all elements in a sequence.
-- Returns 0 for an empty sequence (additive identity).
-- @param sequence The input sequence
-- @return The sum
function sum(sequence)
  return reduce(sequence, operators.add, 0)
end

--- Returns the product of all elements in a sequence.
-- Returns 1 for an empty sequence (multiplicative identity).
-- @param sequence The input sequence
-- @return The product
function product(sequence)
  return reduce(sequence, operators.mul, 1)
end

--- Internal implementation for zip functions.
-- @param iterators Table of iterator functions
-- @param result_handler Function to process the result tuple
-- @return Iterator function
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

--- Zips multiple sequences together, returning packed tables.
-- Each iteration returns a table containing one element from each sequence.
-- @param ... Multiple sequences
-- @return Iterator yielding (control, table) pairs
function zip_packed(...)
  return zip_impl({...}, noop)
end

--- Zips multiple sequences together, returning unpacked values.
-- Each iteration returns multiple values, one from each sequence.
-- @param ... Multiple sequences
-- @return Iterator yielding (control, value1, value2, ...) tuples
-- @usage
-- for i, a, b in zip(List{1, 2, 3}, List{4, 5, 6}) do
--   print(a, b)  -- (1, 4), (2, 5), (3, 6)
-- end
function zip(...)
  return zip_impl({...}, unpack)
end

--- Returns the Cartesian product of multiple sequences.
-- Yields all possible combinations of elements from the input sequences.
-- @param ... Multiple sequences
-- @return Iterator, state, and initial control
-- @usage
-- for ctrl, a, b in cartesian_product(List{1, 2}, List{'a', 'b'}) do
--   print(a, b)  -- (1, 'a'), (1, 'b'), (2, 'a'), (2, 'b')
-- end
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

--- Maps a function over a sequence and flattens the results.
-- Each element is transformed to an iterable, then all
-- iterables are concatenated.
-- @param lambda Function that returns an iterable for each element
-- @param sequence Input sequence
-- @return Iterator over flattened results
-- @usage
-- local function duplicate(x)
--   return List{x, x}
-- end
-- for i, v in flatmap(duplicate, List{1, 2, 3}) do
--   print(v)  -- 1, 1, 2, 2, 3, 3
-- end
function flatmap(lambda, sequence)
  local current_inner = nil
  local inner_control = nil
  local outer_control = nil

  return function()
    while true do
      if current_inner then
        local ctrl, value = current_inner(nil, inner_control)
        if ctrl then
          inner_control = ctrl
          return ctrl, value
        end
        current_inner = nil
        inner_control = nil
      end

      local outer_value
      outer_control, outer_value = sequence(nil, outer_control)
      if not outer_control then
        return nil
      end

      current_inner = lambda(outer_value)
      inner_control = nil
    end
  end
end

--- Splits a sequence into two lists based on a predicate.
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return Two lists: matches (predicate true), non_matches (predicate false)
-- @usage
-- local evens, odds = partition(function(x) return x % 2 == 0 end, range(10))
function partition(predicate, sequence)
  predicate = predicate or nonnil
  local matches = List{}
  local non_matches = List{}

  for i, v in sequence do
    if predicate(v) then
      matches:insert(v)
    else
      non_matches:insert(v)
    end
  end

  return matches, non_matches
end

--- Returns the first element matching the predicate.
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return The first matching element, or nil if not found
function find(predicate, sequence)
  predicate = predicate or nonnil
  for i, v in sequence do
    if predicate(v) then
      return v
    end
  end
  return nil
end

--- Returns the index of the first element matching the predicate.
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return The index of the first matching element, or nil if not found
function find_index(predicate, sequence)
  predicate = predicate or nonnil
  for i, v in sequence do
    if predicate(v) then
      return i
    end
  end
  return nil
end

--- Returns unique elements from a sequence.
-- Preserves order of first appearance.
-- @param sequence Input sequence
-- @param key_func Optional function to compute uniqueness key
-- @return List of unique elements
-- @usage
-- distinct(List{1, 2, 2, 3, 1})  -- Returns List{1, 2, 3}
function distinct(sequence, key_func)
  key_func = key_func or noop
  local seen = {}
  local result = List{}

  for i, v in sequence do
    local key = key_func(v) or v
    if not seen[key] then
      seen[key] = true
      result:insert(v)
    end
  end

  return result
end

--- Alias for distinct.
-- @see distinct
unique = distinct

--- Flattens a nested sequence by one level.
-- @param sequence Input sequence of sequences
-- @return Iterator over flattened results
function flatten(sequence)
  return flatmap(noop, sequence)
end

--- Returns pairs of (index, value) for a sequence.
-- Like Python's enumerate().
-- @param sequence Input sequence
-- @param start Starting index (default: 1)
-- @return Iterator returning (control, index, value) tuples
-- @usage
-- for ctrl, i, v in enumerate(List{'a', 'b', 'c'}) do
--   print(i, v)  -- 1 'a', 2 'b', 3 'c'
-- end
function enumerate(sequence, start)
  start = start or 1
  local index = start - 1
  return function(state, control)
    local ctrl, value = sequence(state, control)
    if ctrl then
      index = index + 1
      return ctrl, index, value
    end
    return nil
  end
end

--- Creates a memoized version of a function.
-- Caches results based on arguments for faster repeated calls.
-- @param func Function to memoize
-- @param key_func Optional function to compute cache key from arguments
-- @return Memoized function
-- @usage
-- local fib = memoize(function(n)
--   if n <= 1 then return n end
--   return fib(n-1) + fib(n-2)
-- end)
function memoize(func, key_func)
  local cache = {}

  key_func = key_func or function(...)
    local args = {...}
    local n = select('#', ...)
    if n == 0 then return "" end
    if n == 1 then return args[1] end
    -- Use \0 as separator (cannot appear in tostring output) and include
    -- argument count to avoid collisions between different arities.
    local parts = {tostring(n)}
    for i = 1, n do
      parts[i + 1] = tostring(args[i])
    end
    return table.concat(parts, "\0")
  end

  return function(...)
    local key = key_func(...)
    if cache[key] ~= nil then
      return cache[key]
    end
    local result = func(...)
    cache[key] = result
    return result
  end
end

--- Returns true if any element satisfies the predicate.
-- Short-circuits on first match.
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return true if any element matches, false otherwise
function any(predicate, sequence)
  predicate = predicate or nonnil
  for _, v in sequence do
    if predicate(v) then
      return true
    end
  end
  return false
end

--- Returns true if all elements satisfy the predicate.
-- Short-circuits on first non-match.
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return true if all elements match, false otherwise
function all(predicate, sequence)
  predicate = predicate or nonnil
  for _, v in sequence do
    if not predicate(v) then
      return false
    end
  end
  return true
end

--- Returns true if no elements satisfy the predicate.
-- Equivalent to not any(predicate, sequence).
-- @param predicate Function to test each element (default: nonnil)
-- @param sequence Input sequence
-- @return true if no elements match, false otherwise
function none(predicate, sequence)
  return not any(predicate, sequence)
end

--- Returns a new function with some arguments pre-filled from the left.
-- @param func The function to partially apply
-- @param ... Arguments to pre-fill
-- @return A new function that calls func with the pre-filled arguments
--   followed by any additional arguments
-- @usage
-- local add5 = partial(function(a, b) return a + b end, 5)
-- add5(3)  -- returns 8
function partial(func, ...)
  local bound = table.pack(...)
  return function(...)
    local args = {}
    for i = 1, bound.n do
      args[i] = bound[i]
    end
    local extra = table.pack(...)
    for i = 1, extra.n do
      args[bound.n + i] = extra[i]
    end
    return func(table.unpack(args, 1, bound.n + extra.n))
  end
end

--- Composes functions right-to-left.
-- compose(f, g)(x) equals f(g(x)). The rightmost function may accept
-- multiple arguments; all others receive a single value.
-- @param ... Functions to compose
-- @return A new function representing the composition
-- @usage
-- local double_then_inc = compose(inc, double)
-- double_then_inc(3)  -- returns 7 (inc(double(3)))
function compose(...)
  local fns = table.pack(...)
  return function(...)
    local result = table.pack(fns[fns.n](...))
    for i = fns.n - 1, 1, -1 do
      result = table.pack(fns[i](table.unpack(result, 1, result.n)))
    end
    return table.unpack(result, 1, result.n)
  end
end

--- Composes functions left-to-right.
-- pipe(f, g)(x) equals g(f(x)). The first function may accept
-- multiple arguments; all others receive a single value.
-- @param ... Functions to compose
-- @return A new function representing the pipeline
-- @usage
-- local double_then_inc = pipe(double, inc)
-- double_then_inc(3)  -- returns 7 (inc(double(3)))
function pipe(...)
  local fns = table.pack(...)
  return function(...)
    local result = table.pack(fns[1](...))
    for i = 2, fns.n do
      result = table.pack(fns[i](table.unpack(result, 1, result.n)))
    end
    return table.unpack(result, 1, result.n)
  end
end

--- Auto-curries a function of n arguments.
-- Calling with fewer than n arguments returns a partially applied function.
-- @param func The function to curry
-- @param n The number of arguments (arity)
-- @return A curried version of func
function curry(func, n)
  local function curried(args, num_args)
    if num_args >= n then
      return func(table.unpack(args, 1, num_args))
    end
    return function(...)
      local new_args = {}
      for i = 1, num_args do new_args[i] = args[i] end
      local extra = table.pack(...)
      for i = 1, extra.n do new_args[num_args + i] = extra[i] end
      return curried(new_args, num_args + extra.n)
    end
  end
  return function(...)
    local args = table.pack(...)
    return curried({...}, args.n)
  end
end

--- Swaps the first two arguments of a function.
-- @param func The function to flip
-- @return A new function with the first two arguments swapped
function flip(func)
  return function(a, b, ...)
    return func(b, a, ...)
  end
end

--- Returns the logical negation of a predicate function.
-- @param predicate The predicate to negate
-- @return A function returning not predicate(...)
function negate(predicate)
  return function(...)
    return not predicate(...)
  end
end

--- Creates a function that only executes once, caching the result.
-- Subsequent calls return the cached result from the first call.
-- @param func The function to wrap
-- @return A function that only calls func once
function once(func)
  local called = false
  local result
  return function(...)
    if not called then
      result = table.pack(func(...))
      called = true
    end
    return table.unpack(result, 1, result.n)
  end
end

--- Returns a function that always returns the given value.
-- @param value The value to return
-- @return A function that ignores its arguments and returns value
function constant(value)
  return function()
    return value
  end
end

--- Returns its arguments unchanged.
-- @param ... Any arguments
-- @return The same arguments
function identity(...)
  return ...
end

--- Removes falsey (nil and false) values from a sequence.
-- @param sequence Input iterator
-- @return Iterator yielding only truthy values
function compact(sequence)
  local elements = List{}
  for _, v in sequence do
    if v then
      elements:insert(v)
    end
  end
  local index = 0
  return function()
    index = index + 1
    if index > #elements then return nil end
    return index, elements[index]
  end
end

--- Returns a new List with elements in random order (Fisher-Yates shuffle).
-- Does not modify the input.
-- @param sequence Input iterator or list
-- @return A new shuffled List
function shuffle(sequence)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  local n = #elements
  for i = n, 2, -1 do
    local j = math.random(1, i)
    elements[i], elements[j] = elements[j], elements[i]
  end
  return elements
end

--- Returns n randomly selected elements from a sequence.
-- Does not modify the input.
-- @param sequence Input iterator or list
-- @param n Number of elements to sample
-- @return A new List of sampled elements
function sample(sequence, n)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  -- Fisher-Yates partial shuffle
  local len = #elements
  if n > len then n = len end
  for i = 1, n do
    local j = math.random(i, len)
    elements[i], elements[j] = elements[j], elements[i]
  end
  local result = List{}
  for i = 1, n do
    result:insert(elements[i])
  end
  return result
end

--- Returns a sorted List from any iterator.
-- Does not modify the input.
-- @param sequence Input iterator or list
-- @param cmp Optional comparator function
-- @return A new sorted List
function sorted(sequence, cmp)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  table.sort(elements, cmp)
  return elements
end

--- Generates an infinite sequence by repeated function application.
-- Yields seed, f(seed), f(f(seed)), ...
-- @param f The function to apply repeatedly
-- @param seed The initial value
-- @return Iterator yielding (index, value) pairs
function iterate(f, seed)
  local index = 0
  local current = seed
  local first = true
  return function()
    if first then
      first = false
    else
      current = f(current)
    end
    index = index + 1
    return index, current
  end
end

--- Sorts a sequence using a key-extraction function (Schwartzian transform).
-- Does not modify the input.
-- @param sequence Input iterator or list
-- @param key_func Function to extract the sort key from each element
-- @return A new sorted List
function sort_by(sequence, key_func)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  local keys = {}
  for i = 1, #elements do
    keys[i] = key_func(elements[i])
  end
  -- Build index array, sort by key, extract
  local indices = {}
  for i = 1, #elements do indices[i] = i end
  table.sort(indices, function(a, b)
    if keys[a] == keys[b] then return a < b end
    return keys[a] < keys[b]
  end)
  local result = List{}
  for i = 1, #indices do
    result:insert(elements[indices[i]])
  end
  return result
end

--- Returns the element with the minimum value of a key function.
-- @param sequence Input iterator or list
-- @param key_func Function to extract the comparison key
-- @return The element with the minimum key
function min_by(sequence, key_func)
  local best = nil
  local best_key = nil
  for _, v in sequence do
    local k = key_func(v)
    if best_key == nil or k < best_key then
      best = v
      best_key = k
    end
  end
  return best
end

--- Returns the element with the maximum value of a key function.
-- @param sequence Input iterator or list
-- @param key_func Function to extract the comparison key
-- @return The element with the maximum key
function max_by(sequence, key_func)
  local best = nil
  local best_key = nil
  for _, v in sequence do
    local k = key_func(v)
    if best_key == nil or k > best_key then
      best = v
      best_key = k
    end
  end
  return best
end

--- Recursively flattens nested lists to a given depth.
-- @param sequence Input list
-- @param depth Maximum depth to flatten (default: infinite)
-- @return A new flattened List
function flatten_deep(sequence, depth)
  local result = List{}
  local function helper(seq, d)
    for _, v in seq do
      if type(v) == 'table' and (d == nil or d > 0) then
        helper(v, d and d - 1 or nil)
      else
        result:insert(v)
      end
    end
  end
  helper(sequence, depth)
  return result
end

--- Returns overlapping windows of a given width over a sequence.
-- Generalizes pairwise to arbitrary window sizes.
-- @param sequence Input iterator
-- @param n Window width
-- @return Iterator yielding (index, values...) for each window
function sliding_window(sequence, n)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end

  local len = #elements
  if len < n then
    return function() return nil end
  end

  local pos = 0
  return function()
    pos = pos + 1
    if pos + n - 1 > len then
      return nil
    end
    local window = {}
    for i = 1, n do
      window[i] = elements[pos + i - 1]
    end
    return pos, unpack(window)
  end
end

--- Alternates elements from multiple sequences.
-- Stops when the shortest sequence is exhausted.
-- @param ... Input iterators
-- @return Iterator yielding (index, value) pairs
function interleave(...)
  local sequences = {}
  local min_len = math.huge
  for i = 1, select('#', ...) do
    local seq = select(i, ...)
    local elems = List{}
    for _, v in seq do
      elems:insert(v)
    end
    sequences[i] = elems
    if #elems < min_len then min_len = #elems end
  end

  local num_seqs = #sequences
  local index = 0
  local elem_idx = 1
  local seq_idx = 0

  return function()
    if elem_idx > min_len then
      return nil
    end
    seq_idx = seq_idx + 1
    if seq_idx > num_seqs then
      seq_idx = 1
      elem_idx = elem_idx + 1
      if elem_idx > min_len then
        return nil
      end
    end
    index = index + 1
    return index, sequences[seq_idx][elem_idx]
  end
end

--- Transposes a sequence of tuples into separate lists.
-- Inverse of zip: unzip(zip(a, b)) returns a, b.
-- @param sequence Iterator yielding tables (tuples)
-- @return Multiple Lists, one per position in the tuples
function unzip(sequence)
  local lists = nil
  local width = 0

  for _, tuple in sequence do
    if lists == nil then
      width = #tuple
      lists = {}
      for i = 1, width do
        lists[i] = List{}
      end
    end
    for i = 1, width do
      lists[i]:insert(tuple[i])
    end
  end

  if lists == nil then
    return
  end
  return unpack(lists)
end

--- Generates combinations with replacement from a sequence.
-- Like combinations, but allows repeated elements.
-- @param sequence Input iterator
-- @param r Number of elements per combination
-- @return Iterator yielding (index, values...) for each combination
function combinations_with_replacement(sequence, r)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end

  local n = #elements
  if n == 0 then
    return function() return nil end
  end

  local indices = {}
  for i = 1, r do
    indices[i] = 1
  end

  local function next_combination()
    local i = r
    while i >= 1 and indices[i] == n do
      i = i - 1
    end

    if i < 1 then
      return false
    end

    local next_val = indices[i] + 1
    for j = i, r do
      indices[j] = next_val
    end

    return true
  end

  local first = true
  local index = 0
  return function()
    if first then
      first = false
      index = index + 1
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return index, unpack(result)
    end

    if next_combination() then
      index = index + 1
      local result = {}
      for i = 1, r do
        result[i] = elements[indices[i]]
      end
      return index, unpack(result)
    end

    return nil
  end
end

--- Applies multiple functions to the same arguments, returning all results.
-- @param ... Functions to apply
-- @return A function that returns a List of results from each function
function juxt(...)
  local fns = table.pack(...)
  return function(...)
    local result = List{}
    for i = 1, fns.n do
      result:insert(fns[i](...))
    end
    return result
  end
end

--- Wraps a function so that a wrapper receives it as the first argument.
-- @param func The function to wrap
-- @param wrapper A function that receives func as its first argument
-- @return A new function that delegates to wrapper with func prepended
function wrap(func, wrapper)
  return function(...)
    return wrapper(func, ...)
  end
end

--- Returns a new function with some arguments pre-filled from the right.
-- @param func The function to partially apply
-- @param ... Arguments to append after call-time arguments
-- @return A new function
function partial_right(func, ...)
  local bound = table.pack(...)
  return function(...)
    local args = table.pack(...)
    local all = {}
    for i = 1, args.n do
      all[i] = args[i]
    end
    for i = 1, bound.n do
      all[args.n + i] = bound[i]
    end
    return func(table.unpack(all, 1, args.n + bound.n))
  end
end

--- Generates a sequence by repeatedly applying f to a seed.
-- f(seed) should return (value, next_seed) or nil to stop.
-- @param f Generator function
-- @param seed Initial seed value
-- @return Iterator yielding (index, value) pairs
function unfold(f, seed)
  local index = 0
  local current_seed = seed
  return function()
    local value, next_seed = f(current_seed)
    if value == nil then return nil end
    index = index + 1
    current_seed = next_seed
    return index, value
  end
end

--- Wraps an iterator so that the next value can be peeked without consuming it.
-- @param sequence Input iterator
-- @return A callable table with a :peek() method
function peekable(sequence)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  local pos = 0
  local obj = {}
  function obj:peek()
    if pos + 1 > #elements then return nil end
    return elements[pos + 1]
  end
  setmetatable(obj, {
    __call = function()
      pos = pos + 1
      if pos > #elements then return nil end
      return pos, elements[pos]
    end
  })
  return obj
end

--- Splits a sequence into sublists each time the predicate changes truth value.
-- A new group starts whenever pred(element) changes from false to true
-- or from true to false.
-- @param sequence Input iterator
-- @param pred Predicate function
-- @return A List of Lists
function split_when(sequence, pred)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  if #elements == 0 then return List{} end

  local result = List{}
  local current = List{}
  local prev_match = pred(elements[1])
  for i = 1, #elements do
    local match = pred(elements[i])
    if match ~= prev_match then
      result:insert(current)
      current = List{}
      prev_match = match
    end
    current:insert(elements[i])
  end
  if #current > 0 then
    result:insert(current)
  end
  return result
end

--- Removes consecutive duplicate elements from a sequence.
-- Only adjacent duplicates are removed (unlike distinct which is global).
-- @param sequence Input iterator
-- @param key_func Optional function to compute comparison key
-- @return A List with consecutive duplicates removed
function unique_justseen(sequence, key_func)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  if #elements == 0 then return List{} end

  local result = List{}
  local prev_key = nil
  for i = 1, #elements do
    local k = key_func and key_func(elements[i]) or elements[i]
    if k ~= prev_key then
      result:insert(elements[i])
      prev_key = k
    end
  end
  return result
end

--- Yields every nth element from a sequence (starting with the first).
-- @param sequence Input iterator
-- @param n Step size
-- @return Iterator yielding (index, value) pairs
function take_nth(sequence, n)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  local pos = 1 - n
  local out_index = 0
  return function()
    pos = pos + n
    if pos > #elements then return nil end
    out_index = out_index + 1
    return out_index, elements[pos]
  end
end

--- Reduces a sequence from the right.
-- @param sequence Input iterator or list
-- @param f Binary function (accumulator, value) -> new accumulator
-- @param init Initial accumulator value
-- @return The final accumulated value
function reduce_right(sequence, f, init)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end
  local acc = init
  for i = #elements, 1, -1 do
    acc = f(acc, elements[i])
  end
  return acc
end

--- Zips sequences together and applies a combining function.
-- @param f Combining function
-- @param ... Input sequences
-- @return A List of combined values
function zip_with(f, ...)
  local sequences = {}
  local min_len = math.huge
  for i = 1, select('#', ...) do
    local seq = select(i, ...)
    local elems = List{}
    for _, v in seq do
      elems:insert(v)
    end
    sequences[i] = elems
    if #elems < min_len then min_len = #elems end
  end

  local result = List{}
  for i = 1, min_len do
    local args = {}
    for j = 1, #sequences do
      args[j] = sequences[j][i]
    end
    result:insert(f(table.unpack(args)))
  end
  return result
end

--- Lazy running accumulation (lazy version of accumulate).
-- Yields intermediate results as an iterator.
-- @param sequence Input iterator
-- @param f Binary function (accumulator, value) -> new accumulator
-- @param init Optional initial accumulator value
-- @return Iterator yielding (index, accumulated_value) pairs
function scan(sequence, f, init)
  local elements = List{}
  for _, v in sequence do
    elements:insert(v)
  end

  local acc
  local start_idx
  if init ~= nil then
    acc = init
    start_idx = 1
  else
    if #elements == 0 then
      return function() return nil end
    end
    acc = elements[1]
    start_idx = 2
  end

  local elem_idx = start_idx - 1
  local out_index = 0
  local emitted_first = (init ~= nil)

  return function()
    if not emitted_first then
      emitted_first = true
      out_index = out_index + 1
      return out_index, acc
    end
    elem_idx = elem_idx + 1
    if elem_idx > #elements then return nil end
    acc = f(acc, elements[elem_idx])
    out_index = out_index + 1
    return out_index, acc
  end
end

--- Calls a function with each element for side effects, passing values through.
-- Useful for debugging or logging within a pipeline.
-- @param func Function to call with each element
-- @param sequence Input sequence
-- @return Iterator that passes through all values unchanged
-- @usage
-- for i, v in tap(print, range(3)) do
--   -- prints 1, 2, 3 and also yields them
-- end
function tap(func, sequence)
  return function(state, control)
    local ctrl, value = sequence(state, control)
    if ctrl then
      func(value)
      return ctrl, value
    end
    return nil
  end
end

return _M
