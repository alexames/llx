local types = {}

local function any_type_check()
  return setmetatable({
    __name = 'Any';

    __isinstance = function(value)
      return true
    end;
  }, {
    __tostring = function() return 'types.Any' end;
  })
end

local function union_type_check(type_checker_list)
  local contituent_types = {}
  for i, type_checker in ipairs(type_checker_list) do
    contituent_types[i] = type_checker_list[i]
  end
  local expected_typenames = '{' .. (','):join(contituent_types) .. '}'
  local typename = 'Union' .. expected_typenames
  return setmetatable({
    __name = typename;

    __isinstance = function(value)
      for _, type_checker in ipairs(type_checker_list) do
        if isinstance(value, type_checker) then
          return true
        end
      end
      return false
    end;
  }, {
    __tostring = function() return typename end;
  })
end

local function optional_type_check(type_checker)
  return types.Union{types.Nil, type_checker[1]}
end

local function list_type_check(type_checker)
  local list_type_checker = type_checker[1]
  local typename = 'List{' .. list_type_checker.typename .. '}';
  return setmetatable({
    __name = typename;

    __isinstance = function(value)
      if type(value) ~= 'table' then
        return false
      end
      for _, v in ipairs(value) do
        if not isinstance(v, list_type_checker) then
          return false
        end
      end
      return true
    end;
  }, {
    __tostring = function() return typename end;
  })
end

local function dict_type_check(type_checker)
end

-- Primitive types
types.Nil=nil_table;
types.Number=number;
types.String=string;
types.Boolean=boolean;
types.Function=function_table;
types.Userdata=userdata;
types.Thread=thread;
types.Table=table;

types.Any=any_type_check();
types.Union=union_type_check;
types.Optional=optional_type_check;
types.List=list_type_check;
types.Dict=dict_type_check;
types.Tuple=tuple_type_check;

return types