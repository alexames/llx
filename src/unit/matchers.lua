-- matchers.lua
-- Common matcher predicates for assertions
--
-- @module unit.matchers

local llx = require 'llx'
local isinstance = llx.isinstance

--- Converts a table to a formatted string for display.
local function table_to_string(t)
  local s = '{'
  local first = true
  for k, v in pairs(t) do
    if first then
      s = s .. tostring(k) .. ' = ' .. tostring(v)
      first = false
    else
      s = s .. ', ' .. tostring(k) .. ' = ' .. tostring(v)
    end
  end
  return s .. '}'
end

--- Negates a matcher predicate.
-- @param predicate The matcher to negate
-- @return A new matcher predicate
function negate(predicate)
  return function(actual)
    local result = predicate(actual)
    if type(result) ~= 'table' or result.pass == nil then
      error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
    end
    return {
      pass = not result.pass,
      actual = result.actual,
      positive_message = result.negative_message,
      negative_message = result.positive_message,
      expected = result.expected
    }
  end
end

--- Checks equality with expected value.
function equals(expected)
  return function(actual)
    return {
      pass = actual == expected,
      actual = tostring(actual),
      positive_message = 'be equal to',
      negative_message = 'be not equal to',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual > expected
function greater_than(expected)
  return function(actual)
    return {
      pass = actual > expected,
      actual = tostring(actual),
      positive_message = 'be greater than',
      negative_message = 'be not greater than',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual >= expected
function greater_than_or_equal(expected)
  return function(actual)
    return {
      pass = actual >= expected,
      actual = tostring(actual),
      positive_message = 'be greater than or equal to',
      negative_message = 'be not greater than or equal to',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual < expected
function less_than(expected)
  return function(actual)
    return {
      pass = actual < expected,
      actual = tostring(actual),
      positive_message = 'be less than',
      negative_message = 'be not less than',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual <= expected
function less_than_or_equal(expected)
  return function(actual)
    return {
      pass = actual <= expected,
      actual = tostring(actual),
      positive_message = 'be less than or equal to',
      negative_message = 'be not less than or equal to',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual string starts with expected prefix.
function starts_with(expected)
  return function(actual)
    return {
      pass = actual:startswith(expected),
      actual = tostring(actual),
      positive_message = 'start with',
      negative_message = 'not start with',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual string ends with expected suffix.
function ends_with(expected)
  return function(actual)
    return {
      pass = actual:endswith(expected),
      actual = tostring(actual),
      positive_message = 'end with',
      negative_message = 'not end with',
      expected = tostring(expected)
    }
  end
end

--- Checks if actual is of expected type/class.
function is_of_type(expected)
  return function(actual)
    return {
      pass = isinstance(actual, expected),
      actual = tostring(actual),
      positive_message = 'be of type',
      negative_message = 'not be of type',
      expected = tostring(expected)
    }
  end
end

--- Applies a matcher element-wise to two lists.
-- @param predicate_generator Function producing matchers
-- @param expected The expected list
function listwise(predicate_generator, expected)
  return function(actual)
    local result = true
    local msg
    local act_list, exp_list = {}, {}
    local largest_len = math.max(#actual, #expected)
    for i=1, largest_len do
      local predicate = predicate_generator(expected[i])
      local local_result = predicate(actual[i])
      if type(local_result) ~= 'table' or local_result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      local pass = local_result.pass
      local act = local_result.actual
      local exp = local_result.expected
      msg = local_result.positive_message
      act_list[i], exp_list[i] = act, exp
      result = result and pass
    end
    return {
      pass = result,
      actual = '{' .. (','):join(act_list) .. '}',
      positive_message = msg .. ' the value at every index of',
      negative_message = 'not to ' .. msg .. ' the value at every index of',
      expected = '{' .. (','):join(exp_list) .. '}'
    }
  end
end

--- Gathers keys from multiple tables.
local function collect_keys(out, ...)
  for _, t in ipairs{...} do
    for k in pairs(t) do
      out[k] = true
    end
  end
  return out
end

--- Applies a matcher key-wise to two tables.
-- @param predicate_generator Function producing matchers
-- @param expected The expected table
function tablewise(predicate_generator, expected)
  return function(actual)
    local result = true
    local msg
    local keys = collect_keys({}, actual, expected)
    for k in pairs(keys) do
      local predicate = predicate_generator(expected[k])
      local local_result = predicate(actual[k])
      if type(local_result) ~= 'table' or local_result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      local pass = local_result.pass
      msg = local_result.positive_message
      result = result and pass
    end
    return {
      pass = result,
      actual = table_to_string(actual),
      positive_message = msg .. ' the value at every key of',
      negative_message = 'not to ' .. msg .. ' the value at every key of',
      expected = table_to_string(expected)
    }
  end
end

--- Checks if value is within epsilon of expected (floating point comparison)
function near(expected, epsilon)
  return function(actual)
    local diff = math.abs(actual - expected)
    return {
      pass = diff <= epsilon,
      actual = tostring(actual),
      positive_message = string.format('be within %s of', tostring(epsilon)),
      negative_message = string.format('not be within %s of', tostring(epsilon)),
      expected = tostring(expected)
    }
  end
end

--- Checks if value is NaN
function is_nan()
  return function(actual)
    local is_nan = actual ~= actual
    return {
      pass = is_nan,
      actual = tostring(actual),
      positive_message = 'be NaN',
      negative_message = 'not be NaN',
      expected = 'NaN'
    }
  end
end

--- Checks if value > 0
function is_positive()
  return function(actual)
    return {
      pass = actual > 0,
      actual = tostring(actual),
      positive_message = 'be positive',
      negative_message = 'not be positive',
      expected = '> 0'
    }
  end
end

--- Checks if value < 0
function is_negative()
  return function(actual)
    return {
      pass = actual < 0,
      actual = tostring(actual),
      positive_message = 'be negative',
      negative_message = 'not be negative',
      expected = '< 0'
    }
  end
end

--- Checks if value is between min and max (inclusive)
function is_between(min, max)
  return function(actual)
    return {
      pass = actual >= min and actual <= max,
      actual = tostring(actual),
      positive_message = string.format('be between %s and %s', tostring(min), tostring(max)),
      negative_message = string.format('not be between %s and %s', tostring(min), tostring(max)),
      expected = string.format('[%s, %s]', tostring(min), tostring(max))
    }
  end
end

--- Checks if string contains substring
function contains(substring)
  return function(actual)
    if type(actual) ~= 'string' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'contain',
        negative_message = 'not contain',
        expected = 'string containing: ' .. tostring(substring)
      }
    end
    local contains = actual:find(substring, 1, true) ~= nil
    return {
      pass = contains,
      actual = tostring(actual),
      positive_message = 'contain',
      negative_message = 'not contain',
      expected = tostring(substring)
    }
  end
end

--- Checks if string matches pattern
function matches(pattern)
  return function(actual)
    local matches = type(actual) == 'string' and actual:match(pattern) ~= nil
    return {
      pass = matches,
      actual = tostring(actual),
      positive_message = 'match pattern',
      negative_message = 'not match pattern',
      expected = tostring(pattern)
    }
  end
end

--- Checks if string or collection is empty
function is_empty()
  return function(actual)
    local is_empty = false
    if type(actual) == 'string' then
      is_empty = #actual == 0
    elseif type(actual) == 'table' then
      is_empty = next(actual) == nil
    end
    return {
      pass = is_empty,
      actual = tostring(actual),
      positive_message = 'be empty',
      negative_message = 'not be empty',
      expected = '{} or ""'
    }
  end
end

--- Checks if string has specific length
function has_length(n)
  return function(actual)
    local has_length = type(actual) == 'string' and #actual == n
    return {
      pass = has_length,
      actual = tostring(actual),
      positive_message = 'have length',
      negative_message = 'not have length',
      expected = tostring(n)
    }
  end
end

--- Checks if collection has specific size
function has_size(n)
  return function(actual)
    local size = 0
    if type(actual) == 'table' then
      for _ in pairs(actual) do
        size = size + 1
      end
    end
    return {
      pass = size == n,
      actual = tostring(actual),
      positive_message = 'have size',
      negative_message = 'not have size',
      expected = tostring(n)
    }
  end
end

--- Checks if collection contains element
function contains_element(element)
  return function(actual)
    local contains = false
    if type(actual) == 'table' then
      for _, v in pairs(actual) do
        if v == element then
          contains = true
          break
        end
      end
    end
    return {
      pass = contains,
      actual = tostring(actual),
      positive_message = 'contain element',
      negative_message = 'not contain element',
      expected = tostring(element)
    }
  end
end

--- Checks if all matchers pass
function all_of(...)
  local matchers = {...}
  return function(actual)
    for _, matcher in ipairs(matchers) do
      local result = matcher(actual)
      if type(result) ~= 'table' or result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      if not result.pass then
        return {
          pass = false,
          actual = tostring(actual),
          positive_message = 'match all conditions',
          negative_message = 'not match all conditions',
          expected = 'all matchers'
        }
      end
    end
    return {
      pass = true,
      actual = tostring(actual),
      positive_message = 'match all conditions',
      negative_message = 'not match all conditions',
      expected = 'all matchers'
    }
  end
end

--- Checks if any matcher passes
function any_of(...)
  local matchers = {...}
  return function(actual)
    for _, matcher in ipairs(matchers) do
      local result = matcher(actual)
      if type(result) ~= 'table' or result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      if result.pass then
        return {
          pass = true,
          actual = tostring(actual),
          positive_message = 'match any condition',
          negative_message = 'not match any condition',
          expected = 'any matcher'
        }
      end
    end
    return {
      pass = false,
      actual = tostring(actual),
      positive_message = 'match any condition',
      negative_message = 'not match any condition',
      expected = 'any matcher'
    }
  end
end

--- Checks if none of the matchers pass
function none_of(...)
  local matchers = {...}
  return function(actual)
    for _, matcher in ipairs(matchers) do
      local result = matcher(actual)
      if type(result) ~= 'table' or result.pass == nil then
        error('Matcher must return a table with pass, actual, positive_message, negative_message, and expected fields', 2)
      end
      if result.pass then
        return {
          pass = false,
          actual = tostring(actual),
          positive_message = 'match none of the conditions',
          negative_message = 'match at least one condition',
          expected = 'no matchers'
        }
      end
    end
    return {
      pass = true,
      actual = tostring(actual),
      positive_message = 'match none of the conditions',
      negative_message = 'match at least one condition',
      expected = 'no matchers'
    }
  end
end

--- Checks if value is an instance of a class
function is_instance_of(expected_class)
  return function(actual)
    -- Try to use isinstance if available
    local isinstance_func = llx and llx.isinstance
    if isinstance_func then
      local is_instance = isinstance_func(actual, expected_class)
      return {
        pass = is_instance,
        actual = tostring(actual),
        positive_message = 'be instance of',
        negative_message = 'not be instance of',
        expected = tostring(expected_class)
      }
    end

    -- Fallback: check metatable
    local mt = getmetatable(actual)
    local is_instance = mt == expected_class or (mt and mt.__isinstance and mt:__isinstance(actual))
    return {
      pass = is_instance,
      actual = tostring(actual),
      positive_message = 'be instance of',
      negative_message = 'not be instance of',
      expected = tostring(expected_class)
    }
  end
end

--- Deep equality check for tables
local function deep_equals(a, b, visited)
  if a == b then return true end
  if type(a) ~= type(b) then return false end
  if type(a) ~= 'table' then return false end

  visited = visited or {}
  if visited[a] then return visited[a] == b end
  visited[a] = b

  -- Check all keys in a
  for k, v in pairs(a) do
    if not deep_equals(v, b[k], visited) then
      return false
    end
  end

  -- Check for extra keys in b
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

--- Checks if table deeply equals expected
function match_table(expected)
  return function(actual)
    if type(actual) ~= 'table' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'deeply equal',
        negative_message = 'not deeply equal',
        expected = table_to_string(expected)
      }
    end

    local is_equal = deep_equals(actual, expected)
    return {
      pass = is_equal,
      actual = table_to_string(actual),
      positive_message = 'deeply equal',
      negative_message = 'not deeply equal',
      expected = table_to_string(expected)
    }
  end
end

--- Checks if object has a property with specific value
function have_property(key, expected_value)
  return function(actual)
    if type(actual) ~= 'table' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'have property',
        negative_message = 'not have property',
        expected = string.format('%s = %s', tostring(key), tostring(expected_value))
      }
    end

    local has_key = actual[key] ~= nil
    local value_matches = expected_value == nil or actual[key] == expected_value

    return {
      pass = has_key and value_matches,
      actual = has_key and string.format('%s = %s', tostring(key), tostring(actual[key])) or 'property not found',
      positive_message = 'have property',
      negative_message = 'not have property',
      expected = expected_value and string.format('%s = %s', tostring(key), tostring(expected_value)) or tostring(key)
    }
  end
end

--- Checks if object has a method (callable)
function respond_to(method_name)
  return function(actual)
    if type(actual) ~= 'table' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'respond to',
        negative_message = 'not respond to',
        expected = 'method: ' .. tostring(method_name)
      }
    end

    local method = actual[method_name]
    local is_callable = type(method) == 'function' or (type(method) == 'table' and getmetatable(method) and getmetatable(method).__call)

    return {
      pass = is_callable,
      actual = method and string.format('has %s (%s)', tostring(method_name), type(method)) or 'method not found',
      positive_message = 'respond to',
      negative_message = 'not respond to',
      expected = 'callable method: ' .. tostring(method_name)
    }
  end
end

--- Checks if value is of a specific type
function be_a(type_name)
  return function(actual)
    local actual_type = type(actual)
    return {
      pass = actual_type == type_name,
      actual = actual_type,
      positive_message = 'be of type',
      negative_message = 'not be of type',
      expected = type_name
    }
  end
end

--- Checks if table has all specified keys
function have_keys(...)
  local expected_keys = {...}
  return function(actual)
    if type(actual) ~= 'table' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'have keys',
        negative_message = 'not have keys',
        expected = table.concat(expected_keys, ', ')
      }
    end

    local missing_keys = {}
    for _, key in ipairs(expected_keys) do
      if actual[key] == nil then
        table.insert(missing_keys, tostring(key))
      end
    end

    return {
      pass = #missing_keys == 0,
      actual = #missing_keys > 0 and 'missing: ' .. table.concat(missing_keys, ', ') or 'has all keys',
      positive_message = 'have keys',
      negative_message = 'not have keys',
      expected = table.concat(expected_keys, ', ')
    }
  end
end

--- Checks if number is even
function be_even()
  return function(actual)
    if type(actual) ~= 'number' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'be even',
        negative_message = 'be odd',
        expected = 'even number'
      }
    end

    return {
      pass = actual % 2 == 0,
      actual = tostring(actual),
      positive_message = 'be even',
      negative_message = 'be odd',
      expected = 'even number'
    }
  end
end

--- Checks if number is odd
function be_odd()
  return function(actual)
    if type(actual) ~= 'number' then
      return {
        pass = false,
        actual = tostring(actual) .. ' (type: ' .. type(actual) .. ')',
        positive_message = 'be odd',
        negative_message = 'be even',
        expected = 'odd number'
      }
    end

    return {
      pass = actual % 2 ~= 0,
      actual = tostring(actual),
      positive_message = 'be odd',
      negative_message = 'be even',
      expected = 'odd number'
    }
  end
end

return {
  negate=negate,
  equals=equals,
  greater_than=greater_than,
  greater_than_or_equal=greater_than_or_equal,
  less_than=less_than,
  less_than_or_equal=less_than_or_equal,
  starts_with=starts_with,
  ends_with=ends_with,
  is_of_type=is_of_type,
  listwise=listwise,
  tablewise=tablewise,
  near=near,
  is_nan=is_nan,
  is_positive=is_positive,
  is_negative=is_negative,
  is_between=is_between,
  contains=contains,
  matches=matches,
  is_empty=is_empty,
  has_length=has_length,
  has_size=has_size,
  contains_element=contains_element,
  all_of=all_of,
  any_of=any_of,
  none_of=none_of,
  is_instance_of=is_instance_of,
  match_table=match_table,
  have_property=have_property,
  respond_to=respond_to,
  be_a=be_a,
  have_keys=have_keys,
  be_even=be_even,
  be_odd=be_odd,
}
