-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

function description(v)
  return {
    type = 'description',
    value = v
  }
end
function arguments(v)
  return {
    type = 'arguments',
    value = v
  }
end
function returns(v)
  return {
    type = 'returns',
    value = v
  }
end
argument = setmetatable({}, {
  __index = function(self, argument_name)
    return function(self, description)
      return {
        type = 'arguments',
        argument_name = argument_name,
        description = description,
      }
    end
  end
})
function returnvalue(v)
  return {
    type = 'returnvalue',
    value = v
  }
end

local documentation_table = {}
function documentation(doctable)
  local info = debug.getinfo(2, 'nf')
  local func = info.func
  local name = info.name
  local function_docs = {name=name}
  documentation_table[func] = function_docs
  for i, v in pairs(doctable) do
    local type = v.type
    assert(not function_docs[type])
    function_docs[type] = v.value
  end
end

function describe(func, describer)
  local docs = documentation_table[func]
  print('# ' .. docs.name)
  if docs.description then
    print()
    print(docs.description)
  end
  if docs.arguments then
    print()
    print('## Arguments')
    for i, v in ipairs(docs.arguments) do
      print('  * ' .. v.argument_name .. ': ' .. v.description)
    end
  end
  if docs.returns then
    print()
    print('## Return Values')
    for i, v in ipairs(docs.returns) do
      print('  ' .. tostring(i) .. '. ' .. v.value)
    end
  end
end

function add(lhs, rhs)
  documentation {
    description 'A function that adds two numbers',
    arguments {
      argument: lhs 'The left hand side of the equation',
      argument: rhs 'The right hand side of the equation',
    },
    returns {
      returnvalue 'The sum of the two operands',
    }
  }
  return lhs + rhs
end

add(2, 5)

describe(add, md)