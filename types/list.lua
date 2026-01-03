-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local is_callable = require 'llx.core' . is_callable
local isinstance = require 'llx.isinstance' . isinstance
local Number = require 'llx.types.number' . Number
local String = require 'llx.types.string' . String
local Table = require 'llx.types.table' . Table

local _ENV, _M = environment.create_module_environment()

List = class 'List' : extends(Table) {
  __new = function(iterable)
    if is_callable(iterable) then
      local list = {}
      local i = 0
      for k, v in iterable do
        i = i + 1
        list[i] = v
      end
      return list
    end
    return iterable or {}
  end,

  extend = function(self, other)
    for i, v in ipairs(other) do
      self:insert(v)
    end
  end,

  contains = function(self, value)
    for i=1, #self do
      local element = self[i]
      if value == element then
        return true
      end
    end
    return false
  end,

  sub = function(self, start, finish, step)
    local length = #self
    start = start or 1
    finish = finish or length
    step = step or 1

    if start < 0 then start = length + start + 1 end
    if start < 1 then start = 1
    elseif start > length then start = length end

    if finish < 0 then finish = length + finish + 1 end
    if finish < 0 then finish = 0
    elseif finish > length then finish = length end
    local result = List{}
    local dest = 1
    for src=start, finish, step do
      result[dest] = self[src]
      dest = dest + 1
    end
    return result
  end,

  reverse = function(self)
    return self:sub(#self, 1, -1)
  end,

  __eq = function(self, other)
    if #self ~= #other then
      return false
    end
    for i, v in ipairs(self) do
      if v ~= other[i] then
        return false
      end
    end
    return true
  end,

  __tostring = function(self)
    return 'List{' .. (', '):join(self) .. '}'
  end,

  __index = function(self, index)
    if isinstance(index, Number) then
      if index < 0 then
        index = #self + index + 1
      end
      return rawget(self, index)
    elseif isinstance(index, Table) then
      local results = List{}
      for i, v in ipairs(index) do
        results[i] = self[v]
      end
      return results
    else
      return List.__defaultindex(self, index)
    end
  end,

  __concat = function(self, other)
    local result = List{}
    for i=1, #self do
      result:insert(self[i])
    end
    for i=1, #other do
      result:insert(other[i])
    end
    return result
  end,

  __mul = function(self, num_copies)
    if type(self) == 'number' then
      self, num_copies = num_copies, self
    end
    local result = List{}
    for i=1, num_copies do
      result:extend(self)
    end
    return result
  end,

  __call = function(self, state, control)
    control = (control or 0) + 1
    local value = self[control]
    return value and control, value
  end,

  __shl = function(self, n)
    if n < 0 then return self >> -n
    elseif n == 0 then return self
    else return self:sub(n + 1) .. self:sub(1, n)
    end
  end,

  __shr = function(self, n)
    if n < 0 then return self << -n
    elseif n == 0 then return self
    else return self:sub(-(n)) .. self:sub(1, -(n + 1))
    end
  end,

  __validate = function(self, schema, path, level, check_field)
    local items = schema.items
    local prefix_items = schema.prefix_items or {}
    if not items then return true end

    local exception_list = {}
    for i=1, #self do
      local value = self[i]
      local item_schema = prefix_items[i] or items
      if not item_schema then
        break
      end
      Table.insert(path, i)
      local successful, exception =
          check_field(item_schema, value, path, level + 1)
      if not successful then
        Table.insert(exception_list, exception)
      end
      Table.remove(path)
    end
    if #exception_list > 0 then
      return false, ExceptionGroup(exception_list, level + 1)
    end
    return true
  end,

  --- Map: Apply a function to each element and return a new list
  -- @param func Function to apply to each element
  -- @return New list with mapped values
  map = function(self, func)
    local result = List{}
    for i, v in ipairs(self) do
      result:insert(func(v, i))
    end
    return result
  end,

  --- Filter: Keep only elements that match the predicate
  -- @param predicate Function to test each element
  -- @return New list with filtered values
  filter = function(self, predicate)
    local result = List{}
    for i, v in ipairs(self) do
      if predicate(v, i) then
        result:insert(v)
      end
    end
    return result
  end,

  --- Reduce: Reduce the list to a single value
  -- @param func Reducer function (accumulator, value, index)
  -- @param initial Initial value for the accumulator
  -- @return Reduced value
  reduce = function(self, func, initial)
    local accumulator = initial
    local start_index = 1

    if initial == nil then
      if #self == 0 then
        error('Reduce of empty list with no initial value', 2)
      end
      accumulator = self[1]
      start_index = 2
    end

    for i = start_index, #self do
      accumulator = func(accumulator, self[i], i)
    end

    return accumulator
  end,

  --- Find: Return the first element matching the predicate
  -- @param predicate Function to test each element
  -- @return First matching element, or nil
  find = function(self, predicate)
    for i, v in ipairs(self) do
      if predicate(v, i) then
        return v
      end
    end
    return nil
  end,

  --- Find index: Return the index of the first matching element
  -- @param predicate Function to test each element
  -- @return Index of first match, or nil
  find_index = function(self, predicate)
    for i, v in ipairs(self) do
      if predicate(v, i) then
        return i
      end
    end
    return nil
  end,

  --- Sort: Sort the list in place (or return new sorted list)
  -- @param comparator Optional comparison function (a, b) -> boolean
  -- @param in_place If true, sort in place; otherwise return new list
  -- @return Sorted list
  sort = function(self, comparator, in_place)
    local target = in_place and self or List{}
    if not in_place then
      for _, v in ipairs(self) do
        target:insert(v)
      end
    end

    if comparator then
      table.sort(target, comparator)
    else
      table.sort(target)
    end

    return target
  end,

  --- Group by: Group elements by a key function
  -- @param key_func Function to compute the grouping key
  -- @return Table mapping keys to lists of elements
  group_by = function(self, key_func)
    local groups = {}
    local group_order = List{}

    for i, v in ipairs(self) do
      local key = key_func(v, i)
      if not groups[key] then
        groups[key] = List{}
        group_order:insert(key)
      end
      groups[key]:insert(v)
    end

    -- Return both the groups table and the order of keys
    return groups, group_order
  end,

  --- Zip: Combine this list with another list into pairs
  -- @param other Another list to zip with
  -- @return New list of {a, b} pairs
  zip = function(self, other)
    local result = List{}
    local min_len = math.min(#self, #other)

    for i = 1, min_len do
      result:insert({self[i], other[i]})
    end

    return result
  end,

  --- Flatten: Flatten a list of lists by one level
  -- @return New flattened list
  flatten = function(self)
    local result = List{}
    for _, v in ipairs(self) do
      if type(v) == 'table' then
        for _, inner_v in ipairs(v) do
          result:insert(inner_v)
        end
      else
        result:insert(v)
      end
    end
    return result
  end,

  --- Distinct: Remove duplicate elements
  -- @param key_func Optional function to compute uniqueness key
  -- @return New list with unique elements
  distinct = function(self, key_func)
    local seen = {}
    local result = List{}

    for i, v in ipairs(self) do
      local key = key_func and key_func(v, i) or v
      if not seen[key] then
        seen[key] = true
        result:insert(v)
      end
    end

    return result
  end,

  --- Unique: Alias for distinct
  unique = function(self, key_func)
    return self:distinct(key_func)
  end,

  --- Any: Test if any element matches the predicate
  -- @param predicate Function to test each element
  -- @return true if any element matches, false otherwise
  any = function(self, predicate)
    for i, v in ipairs(self) do
      if predicate(v, i) then
        return true
      end
    end
    return false
  end,

  --- All: Test if all elements match the predicate
  -- @param predicate Function to test each element
  -- @return true if all elements match, false otherwise
  all = function(self, predicate)
    for i, v in ipairs(self) do
      if not predicate(v, i) then
        return false
      end
    end
    return true
  end,

  --- None: Test if no elements match the predicate
  -- @param predicate Function to test each element
  -- @return true if no elements match, false otherwise
  none = function(self, predicate)
    for i, v in ipairs(self) do
      if predicate(v, i) then
        return false
      end
    end
    return true
  end,

  --- Take: Return the first n elements
  -- @param n Number of elements to take
  -- @return New list with first n elements
  take = function(self, n)
    return self:sub(1, math.min(n, #self))
  end,

  --- Drop: Return all elements after the first n
  -- @param n Number of elements to drop
  -- @return New list with remaining elements
  drop = function(self, n)
    return self:sub(n + 1)
  end,

  --- Partition: Split list into two based on predicate
  -- @param predicate Function to test each element
  -- @return Two lists: [matches, non-matches]
  partition = function(self, predicate)
    local matches = List{}
    local non_matches = List{}

    for i, v in ipairs(self) do
      if predicate(v, i) then
        matches:insert(v)
      else
        non_matches:insert(v)
      end
    end

    return matches, non_matches
  end,

  --- Chunk: Split list into chunks of size n
  -- @param n Chunk size
  -- @return New list of chunks
  chunk = function(self, n)
    if n < 1 then
      error('Chunk size must be at least 1', 2)
    end

    local result = List{}
    for i = 1, #self, n do
      local chunk = List{}
      for j = i, math.min(i + n - 1, #self) do
        chunk:insert(self[j])
      end
      result:insert(chunk)
    end

    return result
  end,

  --- Sum: Sum all numeric elements
  -- @return Sum of all elements
  sum = function(self)
    return self:reduce(function(acc, v) return acc + v end, 0)
  end,

  --- Product: Multiply all numeric elements
  -- @return Product of all elements
  product = function(self)
    return self:reduce(function(acc, v) return acc * v end, 1)
  end,

  --- Min: Find minimum element
  -- @param comparator Optional comparison function
  -- @return Minimum element
  min = function(self, comparator)
    if #self == 0 then return nil end

    local min_val = self[1]
    for i = 2, #self do
      if comparator then
        if comparator(self[i], min_val) then
          min_val = self[i]
        end
      else
        if self[i] < min_val then
          min_val = self[i]
        end
      end
    end

    return min_val
  end,

  --- Max: Find maximum element
  -- @param comparator Optional comparison function
  -- @return Maximum element
  max = function(self, comparator)
    if #self == 0 then return nil end

    local max_val = self[1]
    for i = 2, #self do
      if comparator then
        if comparator(self[i], max_val) then
          max_val = self[i]
        end
      else
        if self[i] > max_val then
          max_val = self[i]
        end
      end
    end

    return max_val
  end,

  --- First: Get the first element
  -- @return First element or nil
  first = function(self)
    return self[1]
  end,

  --- Last: Get the last element
  -- @return Last element or nil
  last = function(self)
    return self[#self]
  end,

  --- Is empty: Check if list is empty
  -- @return true if empty, false otherwise
  is_empty = function(self)
    return #self == 0
  end,
}

return _M
