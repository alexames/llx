-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- Extended math utilities.
-- Provides common mathematical and statistical functions not included
-- in Lua's built-in math library.
-- @module llx.mathx

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

--- Clamps a number to a range [lo, hi].
-- @param x The value to clamp
-- @param lo The lower bound
-- @param hi The upper bound
-- @return lo if x < lo, hi if x > hi, otherwise x
-- @usage clamp(15, 0, 10)  -- returns 10
function clamp(x, lo, hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

--- Rounds a number to a given number of decimal places.
-- Rounds half away from zero.
-- @param x The number to round
-- @param precision Number of decimal places (default: 0)
-- @return The rounded number
-- @usage round(3.14159, 2)  -- returns 3.14
function round(x, precision)
  precision = precision or 0
  local mult = 10 ^ precision
  if x >= 0 then
    return math.floor(x * mult + 0.5) / mult
  else
    return math.ceil(x * mult - 0.5) / mult
  end
end

--- Returns the sign of a number.
-- @param x The number to check
-- @return -1 if x < 0, 0 if x == 0, 1 if x > 0
-- @usage sign(-5)  -- returns -1
function sign(x)
  if x > 0 then return 1 end
  if x < 0 then return -1 end
  return 0
end

--- Performs linear interpolation between two values.
-- @param a Start value
-- @param b End value
-- @param t Interpolation parameter (0 = a, 1 = b)
-- @return The interpolated value a + (b - a) * t
-- @usage lerp(0, 10, 0.5)  -- returns 5
function lerp(a, b, t)
  return a + (b - a) * t
end

--- Computes the arithmetic mean of a sequence.
-- @param sequence A table of numbers
-- @return The arithmetic mean
-- @usage mean({1, 2, 3, 4, 5})  -- returns 3
function mean(sequence)
  local sum = 0
  local n = #sequence
  for i = 1, n do
    sum = sum + sequence[i]
  end
  return sum / n
end

--- Computes the median of a sequence.
-- Does not modify the input table.
-- @param sequence A table of numbers
-- @return The median value
-- @usage median({3, 1, 2})  -- returns 2
function median(sequence)
  local sorted = {}
  for i = 1, #sequence do
    sorted[i] = sequence[i]
  end
  table.sort(sorted)
  local n = #sorted
  if n % 2 == 1 then
    return sorted[(n + 1) / 2]
  else
    return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
  end
end

return _M
