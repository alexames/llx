-- examples/07_result_option.lua
-- Result and Option for non-exceptional control flow.

local llx = require 'llx'
local Ok, Err = llx.Ok, llx.Err
local Some, None = llx.Some, llx.None

-- A function that returns Result instead of raising.
local function divide(a, b)
  if b == 0 then return Err('division by zero') end
  return Ok(a / b)
end

-- Pattern: thread errors through map and and_then.
local result = divide(10, 2)
  :map(function(x) return x + 1 end)         -- (10/2)+1 = 6
  :and_then(function(x) return divide(x, 3) end)  -- 6/3 = 2

print(result:unwrap())                       --> 2.0

-- Errors short-circuit; the rest of the chain is skipped.
local err = divide(10, 0)
  :map(function(x) return x + 1 end)         -- skipped
  :and_then(function(x) return divide(x, 3) end)  -- skipped

print(err:is_err())                          --> true
print(err:unwrap_or(-1))                     --> -1

-- Recover with or_else.
local recovered = divide(10, 0):or_else(function(_) return Ok(0) end)
print(recovered:unwrap())                    --> 0

-- Option for "value or absence" without sentinel-nil tricks.
local function find_user(id)
  local users = {[1] = 'Alice', [2] = 'Bob'}
  if users[id] then return Some(users[id]) end
  return None
end

print(find_user(1):unwrap())                 --> Alice
print(find_user(99):unwrap_or('(unknown)'))  --> (unknown)

-- Chain Option transformations.
local greeting = find_user(1)
  :map(function(name) return 'Hello, ' .. name end)
  :unwrap_or('Hello, stranger')
print(greeting)                              --> Hello, Alice

-- Convert Option to Result.
local r = find_user(99):ok_or('user not found')
print(r:is_err(), r:unwrap_err())            --> true, user not found
