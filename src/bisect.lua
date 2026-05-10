-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Binary search on sorted sequences.
-- Mirrors Python's bisect module: returns insertion points that
-- keep a sorted sequence sorted. Both bisect_left and bisect_right
-- accept optional lo/hi bounds and a key extraction function.
-- @module llx.bisect

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

--- Returns the leftmost index at which x can be inserted into a
-- to keep it sorted. All elements before the returned index
-- compare strictly less than x; all elements at and after compare
-- greater than or equal.
-- @param a Sorted sequence (1-indexed).
-- @param x Value to locate.
-- @param lo Optional lower bound (default 1).
-- @param hi Optional upper bound (default #a + 1).
-- @param key Optional function to extract the comparison key from
--   each element.
-- @return Index in [lo, hi] suitable for insertion.
function bisect_left(a, x, lo, hi, key)
  lo = lo or 1
  hi = hi or (#a + 1)
  if key then
    local kx = key(x)
    while lo < hi do
      local mid = (lo + hi) // 2
      if key(a[mid]) < kx then
        lo = mid + 1
      else
        hi = mid
      end
    end
  else
    while lo < hi do
      local mid = (lo + hi) // 2
      if a[mid] < x then
        lo = mid + 1
      else
        hi = mid
      end
    end
  end
  return lo
end

--- Returns the rightmost index at which x can be inserted into a
-- to keep it sorted, placing x after any equal elements.
-- @param a Sorted sequence (1-indexed).
-- @param x Value to locate.
-- @param lo Optional lower bound (default 1).
-- @param hi Optional upper bound (default #a + 1).
-- @param key Optional function to extract the comparison key.
-- @return Index in [lo, hi] suitable for insertion.
function bisect_right(a, x, lo, hi, key)
  lo = lo or 1
  hi = hi or (#a + 1)
  if key then
    local kx = key(x)
    while lo < hi do
      local mid = (lo + hi) // 2
      if kx < key(a[mid]) then
        hi = mid
      else
        lo = mid + 1
      end
    end
  else
    while lo < hi do
      local mid = (lo + hi) // 2
      if x < a[mid] then
        hi = mid
      else
        lo = mid + 1
      end
    end
  end
  return lo
end

--- Alias for bisect_right (matches Python's bisect.bisect).
bisect = bisect_right

--- Inserts x into a at the bisect_left position. Mutates a.
-- @return The index at which x was inserted.
function insort_left(a, x, lo, hi, key)
  local i = bisect_left(a, x, lo, hi, key)
  table.insert(a, i, x)
  return i
end

--- Inserts x into a at the bisect_right position. Mutates a.
-- @return The index at which x was inserted.
function insort_right(a, x, lo, hi, key)
  local i = bisect_right(a, x, lo, hi, key)
  table.insert(a, i, x)
  return i
end

--- Alias for insort_right (matches Python's bisect.insort).
insort = insort_right

return _M
