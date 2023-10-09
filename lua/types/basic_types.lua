local types = {}

local function simple_type_check(expected_typename)
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

local function any_type_check()
  return {
    typename = 'Any';
    check = function(value)
      return true
    end;
  }
end

local function union_type_check(type_checker_list)
  local contituent_types = {}
  for i, type_checker in ipairs(type_checker_list) do
    contituent_types[i] = type_checker_list[i].typename
  end
  local expected_typenames = '{' .. (','):join(contituent_types) .. '}'

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

local function optional_type_check(type_checker)
  return types.Union{types.Nil, type_checker[1]}
end

local function list_type_check(type_checker)
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

local function dict_type_check(type_checker)
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

types.Any=any_type_check();
types.Union=union_type_check;
types.Optional=optional_type_check;
types.List=list_type_check;
types.Dict=dict_type_check;
types.Tuple=tuple_type_check;

return types