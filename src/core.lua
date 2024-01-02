-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

function getmetafield(t, k)
  local metatable = debug.getmetatable(t)
  return metatable and rawget(metatable, k)
end

function printf(fmt, ...)
  print(string.format(fmt, ...))
end

function script_path(level)
   return debug.getinfo((level or 1) + 1, "S").source:sub(2)
end

function main_file(level)
  return script_path((level or 1) + 1) == arg[0]
end

function metamethod_args(class, self, other)
  if isinstance(self, class) then
    return self, other
  else
    return other, self
  end
end

function range(a, b, c)
  local start = b and a or 1
  local finish = b or a
  local step = c or 1
  local up = step > 0
  return function(unused, i)
    i = i + step
    if up and i < finish or i > finish then
      return i
    else
      return nil
    end
  end, nil, start - step
end

function rangelist(a, b, c)
  local result = List{}
  for i in range(a, b, c) do
    result:insert(i)
  end
  return result
end

function values(t)
  local v = nil
  return function()
    return next(t, v)
  end
end

function ivalues(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

function cmp(a, b)
  if a == b then return 0
  elseif a < b then return -1
  else return 1
  end
end

function transform(list, lambda)
  local result = List{}
  for i=1, #list do
    result[i] = lambda(i, list[i])
  end
  return result
end

function reduce(list, lambda, initial_value)
  local result = initial_value or list[1]
  for i=initial_value and 1 or 2, #list do
    result = lambda(result, list[i])
  end
  return result
end

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

function min(list)
  return reduce(list, function(a, b) return a < b and a or b end)
end

function max(list)
  return reduce(list, function(a, b) return a > b and a or b end)
end

function sum(list)
  return reduce(list, add)
end

function product(list)
  return reduce(list, mul)
end
function noop(...) return ... end

function tovalue(s)
  return load('return '.. s)()
end

return {
  getmetafield=getmetafield,
  printf=printf,
  script_path=script_path,
  main_file=main_file,
  metamethod_args=metamethod_args,
  values=values,
  ivalues=ivalues,
  cmp=cmp,
  reduce=reduce,
  add=add,
  sub=sub,
  mul=mul,
  div=div,
  mod=mod,
  pow=pow,
  unm=unm,
  idiv=idiv,
  band=band,
  bor=bor,
  bxor=bxor,
  bnot=bnot,
  shl=shl,
  shr=shr,
  concat=concat,
  len=len,
  eq=eq,
  lt=lt,
  le=le,
  min=min,
  max=max,
  sum=sum,
  product=product,
  noop=noop,
  tovalue=tovalue,
}
