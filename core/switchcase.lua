require 'llx/core/table'

-- switch {
--   value;
--   case(FileNotFoundException, function(e)
--     -- Handle file not found
--   end);
--   case(Any, function(e)
--     -- Handle any other error
--   end);
-- }
default = {}
function switch(value)
  return function(cases)
    local fn = cases[value] or cases[default]
    if fn then fn(value) end
  end
end

local index = 0
function case(value)
  index = index + 1
  return {index=index, value=value}
end

function type_switch(value)
  return function(cases)
    local sorted_cases = {}
    for k, v in pairs(cases) do table.insert(sorted_cases, k) end
    Table.sort(cases, function(a, b) return a.index < b.index end)
    local _, key =
      Table.ifind_if(
        sorted_cases,
        function(i, case)
          return case.value.isinstance(value)
        end)
    local handler = key and cases[key]
    return handler and handler(value)
  end
end

--------------------------------------------------------------------------------

-- switch(10) {
--   [1] = function()
--     print('>> 1')
--   end,
--   [2] = function()
--     print('>>> 2')
--   end,
--   [default] = function(v)
--     print('>default', v)
--   end,
-- }

-- type_switch('fasdfj') {
--   [case(Table)] = function(v) print('String', v) end,
--   [case(Number)] = function(v) print('Number', v) end,
--   [case(Boolean)] = function(v) print('Boolean', v) end,
--   [case(Nil)] = function(v) print('Nil', v) end,
--   [case(Any)] = function(v) print(default) end,
-- }
