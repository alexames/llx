require 'class'

--------------------------------------------------------------------------------
-- Utility

function join(delimiter, t)
  local result = ''
  for i=1, #t do
    if i > 1 then
      result = result .. delimiter
    end
    result = result .. t[i]
  end
  return result
end

--------------------------------------------------------------------------------

function check_types(location, expected_types, argument_list)
  for index, expected_type in ipairs(expected_types) do
    local value = argument_list[index]
    local correct, udata = expected_type.check(value)
    if not correct then
      error(expected_type.invalid_type(location, index, value, udata))
    end
  end
end

function typecheck_decorator(underlying_function, expected_types)
  if not expected_types then
    return underlying_function
  end
  local argument_types = expected_types.args
  local return_types = expected_types.returns
  function type_checker(underlying_function)
    return function(...)
      check_types('argument', argument_types, arg)
      local result = {underlying_function(unpack(arg))}
      check_types('return', return_types, result)
      return unpack(result)
    end
  end
  return type_checker(underlying_function)
end


class 'Function' {
  __init = function(self, function_args)
    local underlying_function = function_args[1]
    for _, decorator in ipairs(function_args.decorators or {}) do
      underlying_function = decorator(underlying_function)
    end
    self.underlying_function = typecheck_decorator(underlying_function, function_args.types)
  end;

  __call = function(self, ...)
    return self.underlying_function(unpack(arg))
  end;
}

--------------------------------------------------------------------------------
-- Decorators

function fakehash(arg)
  return arg[1]
end

function lru(count)
  local cached_values = {}
  
  function cache_result(value, arg)
    -- Assume one argument for now
    for k, v in pairs(cached_values) do print(k, v) end
    cached_values[fakehash(arg)] = value
    return value
  end

  return function(underlying_function)
    return function(...)
      -- Assume one argument for now,
      -- switch fakehash to a real hash of the arguments at some point.
      local result = cached_values[fakehash(arg)]
      if not result then
        result = cache_result({underlying_function(unpack(arg))}, arg)
      end
      return unpack(result)
    end
  end
end

--------------------------------------------------------------------------------
-- Type checkers

local types = {}

function simple_type_check(expected_typename)
  return {
    typename = expected_typename;

    check = function(value)
      local actual_typename = type(value)
      return actual_typename == expected_typename
    end;

    invalid_type = function(location, index, value)
      local actual_typename = type(value)
      if actual_typename ~= expected_typename then
        return string.format(
          '%s expected at %s index %s, got %s',
          expected_typename, location, index, actual_typename)
      end
    end;
  }
end

function any_type_check()
  return {
    typename = 'Any';
    check = function(value)
      return true
    end;
  }
end

function union_type_check(type_checker_list)
  local contituent_types = {}
  for i, type_checker in ipairs(type_checker_list) do
    contituent_types[i] = type_checker_list[i].typename
  end
  local expected_typenames = '{' .. join(',', contituent_types) .. '}'

  return {
    typename = 'Union' .. expected_typenames;

    check = function(value)
      for _, type_checker in ipairs(type_checker_list) do
        if type_checker.check(value) then
          return true
        end
      end
      return false
    end;

    invalid_type = function(location, index, value)
      local actual_typename = type(value)
      if actual_typename ~= expected_typename then
        return string.format(
          'one of %s expected at %s index %s, got %s',
          expected_typenames, location, index, actual_typename)
      end
    end;
  }
end

function optional_type_check(type_checker)
  return types.Union{types.Nil, type_checker[1]}
end

function list_type_check(type_checker)
  list_type_checker = type_checker[1]
  return {
    typename = 'List{' .. list_type_checker.typename .. '}';

    check = function(value)
      if type(value) ~= 'table' then
        return false
      end
      for _, v in ipairs(value) do
        if not list_type_checker.check(v) then
          return false
        end
      end
      return true
    end;

    invalid_type = function(location, index, value)
      local actual_typename = type(value)
      if actual_typename ~= 'table' then
        return string.format(
          'List{%s} expected at %s index %s, got %s',
          list_type_checker.typename, location, index, actual_typename)
      end
      for i, v in ipairs(value) do
        if not list_type_checker.check(v) then
          return string.format(
            'List{%s} expected at %s index %s, got %s at list index %s',
            list_type_checker.typename, location, index, type(v), i)
        end
      end
    end;
  }
end

function dict_type_check(type_checker)
end

-- Primitive types
types.Nil=simple_type_check('nil');
types.Number=simple_type_check('number');
types.String=simple_type_check('string');
types.Boolean=simple_type_check('boolean');
types.Function=simple_type_check('function');
types.Userdata=simple_type_check('userdata');
types.Thread=simple_type_check('thread');
types.Table=simple_type_check('table');

-- Complex types
types.Any=any_type_check();
types.Union=union_type_check;
types.Optional=optional_type_check;
types.List=list_type_check;
types.Dict=dict_type_check;
types.Tuple=tuple_type_check;


local Any, List, Number, Optional, String, Union = types.Any, types.List, types.Number, types.Optional, types.String, types.Union

f = Function{
  decorators={lru(10)};
  types={
    args={Number, List{Union{String, Number}}, Optional{Any}},
    returns={Number}};
  function(i)
    print('hello')
    return 10
  end
}

print(f(10, {'false'}))
print(f(10, {'safdsdf', 'sfsf', 10, 'false'}, 3))


-- TODO:
-- Move join to common utility file
-- Fix error message to be more like built in error message:
--   `bad argument #2 to 'format' (string expected, got nil)`
-- Make it work better with built in types, so you can specify strings with just
--   `string` or `number` instead of having to use type.String, etc
--   this could be done by adding functions directly to the tables for each type
--   or by having a table that uses those types as a key, or something else?
-- Improve lists so they are intrinsically typed
-- Add a dict type checker
-- Add a tuple type checker, both intrinsically typed and not
-- refactor error message to just return a string, and allow them to compose better
-- Add examples of other things that can be checked for, like even numbers
-- move decorators to their own file.
-- better handling of metatable/userdata types