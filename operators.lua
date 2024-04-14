-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

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

return _M
