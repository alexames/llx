local bytecode = require 'bcode'
local util = require 'util'

util.compare_two_functions(
  function()
    local my_table = {}
    local __t, __k, __v = decorator(decorator(my_table, 'test', function()end))
    __t[__k] = __v
  end,
  function()
    local my_table = {
      @decorator
      @decorator
      test = function()end
    }
  end
)

-- Decorators

function global_decorator(t, k, v)
  return t, k, function(...)
    v(...)
    v(...)
    return
  end
end

local function local_decorator(t, k, v)
  return t, k, function(...)
    v(...)
    v(...)
    return
  end
end

local table_decorator = {
  decorator = function(t, k, v)
    return t, k, function(...)
      v(...)
      v(...)
      return
    end
  end
}

-- Case 1: global, function syntax
print '-- Case 1 --'

-- global decorator
@global_decorator
function global_dec_global_func(a, b, c)
  print('success: ', 'global_dec_global_func', a, b, c)
end
global_dec_global_func(1, 2, 3)

-- local decorator
@local_decorator
function local_dec_global_func(a, b, c)
  print('success: ', 'local_dec_global_func', a, b, c)
end
local_dec_global_func(1, 2, 3)

-- table decorator
@table_decorator.decorator
function table_dec_global_func(a, b, c)
  print('success: ', 'table_dec_global_func', a, b, c)
end
table_dec_global_func(1, 2, 3)

-- Case 2: global, value syntax
print '-- Case 2 --'

-- Currently nonfunctional

@global_decorator
global_dec_global_value = function(a, b, c)
  print('success: ', 'global_dec_global_value', a, b, c)
end
global_dec_global_value(1, 2, 3)

-- local decorator
@local_decorator
local_dec_global_value = function(a, b, c)
  print('success: ', 'local_dec_global_value', a, b, c)
end
local_dec_global_value(1, 2, 3)

-- table decorator
@table_decorator.decorator
table_dec_global_value = function(a, b, c)
  print('success: ', 'table_dec_global_value', a, b, c)
end
table_dec_global_value(1, 2, 3)

-- Case 3: local, function syntax
print '-- Case 3 --'

-- global decorator
@global_decorator
local function global_dec_local_func(a, b, c)
  print('success: ', 'global_dec_local_func', a, b, c)
end
global_dec_local_func(1, 2, 3)

-- local decorator
@local_decorator
local function local_dec_local_func(a, b, c)
  print('success: ', 'local_dec_local_func', a, b, c)
end
local_dec_local_func(1, 2, 3)

-- table decorator
@table_decorator.decorator
local function table_dec_local_func(a, b, c)
  print('success: ', 'table_dec_local_func', a, b, c)
end
table_dec_local_func(1, 2, 3)

-- Case 4: local value syntax
print '-- Case 4 --'

-- global decorator
@global_decorator
local global_dec_local_value = function(a, b, c)
  print('success: ', 'global_dec_local_value', a, b, c)
end
global_dec_local_value(1, 2, 3)

-- local decorator
@local_decorator
local local_dec_local_value = function(a, b, c)
  print('success: ', 'local_dec_local_value', a, b, c)
end
local_dec_local_value(1, 2, 3)

-- table decorator
@table_decorator.decorator
local table_dec_local_value = function(a, b, c)
  print('success: ', 'table_dec_local_value', a, b, c)
end
table_dec_local_value(1, 2, 3)

-- Case 5: table value syntax
print '-- Case 5 --'

test_table = {
  @global_decorator
  global_dec_table_value = function(a, b, c)
    print('success: ', 'global_table_value', a, b, c)
  end,

  -- local decorator
  @local_decorator
  local_dec_table_value = function(a, b, c)
    print('success: ', 'local_table_value', a, b, c)
  end,

  -- table decorator
  @table_decorator.decorator
  table_dec_table_value = function(a, b, c)
    print('success: ', 'table_table_value', a, b, c)
  end,
}

test_table.global_dec_table_value(1, 2, 3)
test_table.local_dec_table_value(1, 2, 3)
test_table.table_dec_table_value(1, 2, 3)
