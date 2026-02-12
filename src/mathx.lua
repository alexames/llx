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
  assert(lo <= hi, 'clamp: lo must be <= hi')
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
  local n = #sequence
  assert(n > 0, 'mean: sequence must be non-empty')
  local sum = 0
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
  assert(#sequence > 0, 'median: sequence must be non-empty')
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

--- Computes the greatest common divisor of two integers.
-- Uses the Euclidean algorithm.
-- @param a First integer
-- @param b Second integer
-- @return The GCD
function gcd(a, b)
  a, b = math.abs(a), math.abs(b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

--- Computes the least common multiple of two integers.
-- @param a First integer
-- @param b Second integer
-- @return The LCM
function lcm(a, b)
  if a == 0 or b == 0 then return 0 end
  return math.abs(a) // gcd(a, b) * math.abs(b)
end

--- Computes the factorial of a non-negative integer.
-- @param n A non-negative integer
-- @return n!
function factorial(n)
  assert(n >= 0 and n % 1 == 0, 'factorial: n must be a non-negative integer')
  local result = 1
  for i = 2, n do
    result = result * i
  end
  return result
end

--- Checks whether a value is in the half-open range [lo, hi).
-- @param x The value to check
-- @param lo Lower bound (inclusive)
-- @param hi Upper bound (exclusive)
-- @return true if lo <= x < hi
function in_range(x, lo, hi)
  return x >= lo and x < hi
end

--- Maps a value from one range to another.
-- @param v The input value
-- @param in_lo Input range lower bound
-- @param in_hi Input range upper bound
-- @param out_lo Output range lower bound
-- @param out_hi Output range upper bound
-- @return The remapped value
function remap(v, in_lo, in_hi, out_lo, out_hi)
  assert(in_lo ~= in_hi, 'remap: input range must be non-degenerate')
  return out_lo + (v - in_lo) * (out_hi - out_lo) / (in_hi - in_lo)
end

--- Returns both the quotient and remainder of integer division.
-- Uses floored division (like Python's divmod).
-- @param a Dividend
-- @param b Divisor
-- @return quotient, remainder
function divmod(a, b)
  local q = a // b
  local r = a - q * b
  return q, r
end

--- Returns the most common value in a sequence.
-- For ties, returns the value that appears first.
-- @param sequence A table of values
-- @return The mode
function mode(sequence)
  assert(#sequence > 0, 'mode: sequence must be non-empty')
  local counts = {}
  local order = {}
  for i = 1, #sequence do
    local v = sequence[i]
    if counts[v] == nil then
      counts[v] = 0
      order[#order + 1] = v
    end
    counts[v] = counts[v] + 1
  end
  local best = order[1]
  local best_count = counts[best]
  for i = 2, #order do
    local v = order[i]
    if counts[v] > best_count then
      best = v
      best_count = counts[v]
    end
  end
  return best
end

--- Computes the sample variance of a sequence (divides by n-1).
-- @param sequence A table of numbers
-- @return The sample variance
function variance(sequence)
  local n = #sequence
  assert(n >= 2, 'variance: sequence must have at least 2 elements')
  local m = mean(sequence)
  local sum_sq = 0
  for i = 1, n do
    local d = sequence[i] - m
    sum_sq = sum_sq + d * d
  end
  return sum_sq / (n - 1)
end

--- Computes the population variance of a sequence (divides by n).
-- @param sequence A table of numbers
-- @return The population variance
function pvariance(sequence)
  local n = #sequence
  assert(n > 0, 'pvariance: sequence must be non-empty')
  local m = mean(sequence)
  local sum_sq = 0
  for i = 1, n do
    local d = sequence[i] - m
    sum_sq = sum_sq + d * d
  end
  return sum_sq / n
end

--- Computes the sample standard deviation of a sequence.
-- @param sequence A table of numbers
-- @return The sample standard deviation
function stdev(sequence)
  return math.sqrt(variance(sequence))
end

--- Computes the population standard deviation of a sequence.
-- @param sequence A table of numbers
-- @return The population standard deviation
function pstdev(sequence)
  return math.sqrt(pvariance(sequence))
end

--- Returns true if x is NaN.
-- @param x The value to check
-- @return true if x is NaN
function is_nan(x)
  return x ~= x
end

--- Returns true if x is positive or negative infinity.
-- @param x The value to check
-- @return true if x is infinite
function is_inf(x)
  return x == math.huge or x == -math.huge
end

--- Wraps a value into the range [lo, hi) using modular arithmetic.
-- Useful for circular values like angles.
-- @param x The value to wrap
-- @param lo Lower bound (inclusive)
-- @param hi Upper bound (exclusive)
-- @return The wrapped value
function wrap_around(x, lo, hi)
  assert(hi > lo, 'wrap_around: hi must be > lo')
  local range = hi - lo
  return lo + (x - lo) % range
end

--- Computes the inverse of linear interpolation.
-- Returns the parameter t such that lerp(a, b, t) == v.
-- @param a Start value
-- @param b End value
-- @param v The value to find t for
-- @return t in [0, 1] when v is between a and b
function inverse_lerp(a, b, v)
  assert(a ~= b, 'inverse_lerp: a and b must be distinct')
  return (v - a) / (b - a)
end

--- Computes the harmonic mean of a sequence.
-- @param sequence A table of positive numbers
-- @return The harmonic mean
function harmonic_mean(sequence)
  local n = #sequence
  assert(n > 0, 'harmonic_mean: sequence must be non-empty')
  local sum_recip = 0
  for i = 1, n do
    assert(sequence[i] > 0, 'harmonic_mean: all elements must be positive')
    sum_recip = sum_recip + 1 / sequence[i]
  end
  return n / sum_recip
end

--- Computes the geometric mean of a sequence.
-- @param sequence A table of positive numbers
-- @return The geometric mean
function geometric_mean(sequence)
  local n = #sequence
  assert(n > 0, 'geometric_mean: sequence must be non-empty')
  local sum_log = 0
  for i = 1, n do
    assert(sequence[i] > 0, 'geometric_mean: all elements must be positive')
    sum_log = sum_log + math.log(sequence[i])
  end
  return math.exp(sum_log / n)
end

--- Computes the q-th quantile (0 <= q <= 1) using linear interpolation.
-- @param sequence A table of numbers
-- @param q The quantile (0 = min, 0.5 = median, 1 = max)
-- @return The interpolated quantile value
function quantile(sequence, q)
  assert(#sequence > 0, 'quantile: sequence must be non-empty')
  assert(q >= 0 and q <= 1, 'quantile: q must be in [0, 1]')
  local sorted = {}
  for i = 1, #sequence do
    sorted[i] = sequence[i]
  end
  table.sort(sorted)
  local n = #sorted
  if n == 1 then return sorted[1] end
  local pos = 1 + (n - 1) * q
  local lo = math.floor(pos)
  local hi = math.ceil(pos)
  if lo == hi then return sorted[lo] end
  local frac = pos - lo
  return sorted[lo] + (sorted[hi] - sorted[lo]) * frac
end

return _M
