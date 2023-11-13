require 'llx/src/types/boolean'
require 'llx/src/types/function'
require 'llx/src/types/integer'
require 'llx/src/types/nil'
require 'llx/src/types/number'
require 'llx/src/types/string'
require 'llx/src/types/table'
require 'llx/src/types/thread'
require 'llx/src/types/userdata'

local function any_type_check()
  return setmetatable({
    __name = 'Any';

    __isinstance = function(self, value)
      return true
    end;
  }, {
    __tostring = function() return 'types.Any' end;
  })
end

local function union_type_check(type_checker_list)
  return setmetatable({
    __name = typename;

    __isinstance = function(self, value)
      for _, type_checker in ipairs(type_checker_list) do
        if isinstance(value, type_checker) then
          return true
        end
      end
      return false
    end;
  }, {
    __tostring = function()
      local contituent_types = {}
      for i, type_checker in ipairs(type_checker_list) do
        contituent_types[i] = type_checker_list[i]
      end
      local expected_typenames = '{' .. (','):join(contituent_types) .. '}'
      return 'Union' .. expected_typenames
    end,
  })
end

local function optional_type_check(type_checker)
  return types.Union{types.Nil, type_checker[1]}
end

local function dict_type_check(type_checker)
end

return {
  Any=any_type_check(),
  Union=union_type_check,
  Optional=optional_type_check,
  Dict=dict_type_check,
  Tuple=tuple_type_check,
}
