-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

-- the addition (+) operation.
function add(a, b)
  return a + b
end

-- the subtraction (-) operation.
function sub(a, b)
  return a - b
end

-- the multiplication (*) operation.
function mul(a, b)
  return a * b
end

-- the division (/) operation.
function div(a, b)
  return a / b
end

-- the modulo (%) operation.
function mod(a, b)
  return a % b
end

-- the exponentiation (^) operation.
function pow(a, b)
  return a ^ b
end

-- the negation (unary -) operation.
function unm(a)
  return -a
end

-- the floor division (//) operation.
function idiv(a, b)
  return a // b
end

-- the bitwise AND (&) operation.
function band(a, b)
  return a & b
end

-- the bitwise OR (|) operation.
function bor(a, b)
  return a | b
end

-- the bitwise exclusive OR (binary ~) operation.
function bxor(a, b)
  return a ~ b
end

-- the bitwise NOT (unary ~) operation.
function bnot(a)
  return ~a
end

-- the bitwise left shift (<<) operation.
function shl(a, b)
  return a << b
end

-- the bitwise right shift (>>) operation.
function shr(a, b)
  return a >> b
end

-- the concatenation (..) operation.
function concat(a, b)
  return a .. b
end

-- the length (#) operation.
function len(a)
  return #a
end

-- the equal (==) operation.
function eq(a, b)
  return a == b
end

-- the less than (<) operation.
function lt(a, b)
  return a < b
end

-- the less equal (<=) operation.
function le(a, b)
  return a <= b
end

-- the greater than (>) operation.
function gt(a, b)
  return a > b
end

-- the greater equal (>=) operation.
function ge(a, b)
  return a >= b
end

-- the not equal (~=) operation.
function ne(a, b)
  return a ~= b
end

--- Returns a function that gets a key from a table.
-- Useful as a key-extraction function for sort_by, min_by, etc.
-- @param key The key to extract
-- @return A function that returns t[key]
function itemgetter(key)
  return function(t)
    return t[key]
  end
end

--- Returns a function that accesses a nested attribute via dot-separated path.
-- @param path Dot-separated path string (e.g. "a.b.c")
-- @return A function that returns obj.a.b.c, or nil if any step is nil
function attrgetter(path)
  local keys = {}
  for key in path:gmatch('[^%.]+') do
    keys[#keys + 1] = key
  end
  return function(obj)
    local current = obj
    for i = 1, #keys do
      if current == nil then return nil end
      current = current[keys[i]]
    end
    return current
  end
end

--- Returns a function that calls a named method on an object.
-- @param name Method name
-- @param ... Arguments to pass to the method
-- @return A function that calls obj:name(...)
function methodcaller(name, ...)
  local args = table.pack(...)
  return function(obj)
    return obj[name](obj, table.unpack(args, 1, args.n))
  end
end

-- the logical NOT operation.
function not_(a)
  return not a
end

-- the logical AND operation (returns the value, not a boolean).
function and_(a, b)
  return a and b
end

-- the logical OR operation (returns the value, not a boolean).
function or_(a, b)
  return a or b
end

return _M
