-- examples/02_functional.lua
-- Iterator-based functional programming.

local llx = require 'llx'
local f = require 'llx.functional'

-- range produces an iterator. for-loop consumes it.
print('range(1,5):')
for _, v in f.range(1, 5) do io.write(v, ' ') end
io.write('\n')                           --> 1 2 3 4

-- Map + filter + reduce. Note: operations are fn-first; reductions
-- are seq-first. See README "API Conventions" for the rule.
local sum_of_squares = f.reduce(
  f.map(function(x) return x * x end, f.range(1, 5)),
  function(acc, v) return acc + v end,
  0)
print('sum of squares 1..4 =', sum_of_squares)  --> 30

-- Functional combinators: partial, compose, pipe, curry.
local add = function(a, b) return a + b end
local add5 = f.partial(add, 5)
print('add5(3) =', add5(3))                     --> 8

local double = function(x) return x * 2 end
local inc = function(x) return x + 1 end
print('pipe(double, inc)(3) =', f.pipe(double, inc)(3))  --> 7

-- itertools-style: zip, chain, combinations, permutations.
print('zip([1,2,3], ["a","b","c"]):')
for _, a, b in f.zip(f.range(1, 4),
                     function(_, c)
                       c = (c or 0) + 1
                       local letters = {'a', 'b', 'c'}
                       if c > 3 then return nil end
                       return c, letters[c]
                     end) do
  io.write(a, '=', b, ' ')
end
io.write('\n')                                  --> 1=a 2=b 3=c

-- Reductions: min, max, sum, product, find.
print('max =', f.max(f.range(1, 100)))          --> 99
print('first even >5 =',
  f.find(function(x) return x % 2 == 0 and x > 5 end, f.range(1, 20)))  --> 6

-- group_by: collect into buckets by a key function.
for key, vs in f.group_by(f.range(1, 10), function(x) return x % 3 end) do
  io.write('mod3=', key, ': [')
  for _, v in vs do io.write(v, ' ') end
  io.write(']\n')
end
