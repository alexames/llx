-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

function getmetafield(t, k)
  local metatable = debug.getmetatable(t)
  return metatable and rawget(metatable, k)
end

-- function make_is_able_function(key)
--   return function(v)
--     if type(v) == 'function' then return true end
--     local metafield = getmetafield(v, key)
--     return metafield and type(metafield) == 'function'
--   end
-- end
--
-- is_addable = make_is_able_function('__add')
-- is_subable = make_is_able_function('__sub')
-- is_mulable = make_is_able_function('__mul')
-- is_divable = make_is_able_function('__div')
-- is_modable = make_is_able_function('__mod')
-- is_powable = make_is_able_function('__pow')
-- is_unmable = make_is_able_function('__unm')
-- is_idivable = make_is_able_function('__idiv')
-- is_bandable = make_is_able_function('__band')
-- is_borable = make_is_able_function('__bor')
-- is_bxorable = make_is_able_function('__bxor')
-- is_bnotable = make_is_able_function('__bnot')
-- is_shlable = make_is_able_function('__shl')
-- is_shrable = make_is_able_function('__shr')
-- is_concatable = make_is_able_function('__concat')
-- is_lenable = make_is_able_function('__len')
-- is_eqable = make_is_able_function('__eq')
-- is_ltable = make_is_able_function('__lt')
-- is_leable = make_is_able_function('__le')

function is_callable(v)
  if type(v) == 'function' then return true end
  local metafield = getmetafield(v, key)
  return metafield and type(metafield) == 'function'
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

-- like the less than (<) operation, but returns the lesser value (instead of a boolean)
function lesser(a, b)
  return a < b and a or b
end

-- like the greater than (>) operation, but returns the greater value (instead of a boolean)
function greater(a, b)
  return a > b and a or b
end

function even(v) return v % 2 == 0 end

function odd(v) return v % 2 == 1 end

function nonnil(v)
  return v ~= nil
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
  lesser=lesser,
  greater=greater,
  noop=noop,
  tovalue=tovalue,
}
