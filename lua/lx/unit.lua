require 'ext/string'
require 'lx/base'
require 'lx/terminal_colors'

-- Utilities

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

--------------------------------------------------------------------------------
local fmt = 'expected\n  %s\nto %s\n  %s'
function EXPECT_THAT(actual, predicate)
  result, act, msg, nmsg, exp = predicate(actual, false)
  if not result then
    error(fmt:format(act, msg, exp))
  end
end

function EXPECT_TRUE(actual)
  EXPECT_THAT(actual, Equals(true))
end

function EXPECT_FALSE(actual)
  EXPECT_THAT(actual, Equals(false))
end

function EXPECT_EQ(actual, expected)
  EXPECT_THAT(actual, Equals(expected))
end

function EXPECT_NE(actual, expected)
  EXPECT_THAT(actual, Not(Equals(expected)))
end

function Not(predicate)
  return function(actual)
    local result, act, msg, nmsg, exp = predicate(actual)
    return not result, act, nmsg, msg, exp
  end
end

function Equals(expected)
  return function(actual)
    local result = (actual == expected)
    return
      result,
      tostring(actual),
      'be equal to',
      'be not equal to',
      tostring(expected)
  end
end

function GreaterThan(expected)
  return function(actual)
    local result = (actual > expected)
    return
      result,
      tostring(actual),
      'be greater than',
      'be not greater than',
      tostring(expected)
  end
end

function GreaterThanOrEqual(expected)
  return function(actual)
    local result = (actual >= expected)
    return
      result,
      tostring(actual),
      'be greater than or equal to',
      'be not greater than or equal to',
      tostring(expected)
  end
end

function LessThan(expected)
  return function(actual)
    local result = (actual < expected)
    return
      result,
      tostring(actual),
      'be less than',
      'be not less than',
      tostring(expected)
  end
end

function LessThanOrEqual(expected)
  return function(actual)
    local result = (actual <= expected)
    return
      result,
      tostring(actual),
      'be less than or equal to',
      'be not less than or equal to',
      tostring(expected)
  end
end

function StartsWith(expected)
  return function(actual)
    local result = actual:startswith(expected)
    return
      result,
      tostring(actual),
      'start with',
      'not start with',
      tostring(expected)
  end
end

function EndsWith(expected)
  return function(actual)
    local result = actual:endswith(expected)
    return
      result,
      tostring(actual),
      'end with',
      'not end with',
      tostring(expected)
  end
end

function Listwise(predicate_generator, expected)
  return function(actual)
    local result = true
    local act, msg, nmsg, exp
    local act_list, exp_list = {}, {}
    for i=1, max(#actual, #expected) do
      local predicate = predicate_generator(expected[i])
      local local_result
      local_result, act, msg, nmsg, exp = predicate(actual[i])
      act_list[i], exp_list[i] = act, exp
      result = result and local_result
    end
    return result,
           '{' .. (','):join(act_list) .. '}',
           msg .. ' the value at every index of',
           'not to ' .. msg .. ' the value at every index of',
           '{' .. (','):join(exp_list) .. '}'
  end
end

function Tablewise(predicate_generator, expected)
  return function(actual)
    local result = true
    local act, msg, nmsg, exp
    local act_list, exp_list = {}, {}
    local keys = collect_keys({}, actual, expected)
    for k, _ in pairs(keys) do
      local predicate = predicate_generator(expected[k])
      local local_result
      local_result, act, msg, nmsg, exp = predicate(actual[k])
      result = result and local_result
    end
    return result,
           table_to_string(actual),
           msg .. ' the value at every key of',
           'not to ' .. msg .. ' the value at every key of',
           table_to_string(expected)
  end
end

local TestCaseList = {}
function TestCase(name)
  local testCase = {}
  testCase.name = name
  table.insert(TestCaseList, testCase)
  return setmetatable({}, {
    __call = function(self, testCaseTable)
      testCase.tests = testCaseTable
    end
  })
end

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function RunUnitTests()
  for _, testCase in ipairs(TestCaseList) do
    print('[==========] Running tests from ' .. testCase.name)
    for name, test in pairs(testCase.tests) do
      if starts_with(name, 'test_') then
        print('[ Run      ] ' .. testCase.name .. '.' .. name)
        local ok, err = pcall(test)
        if ok then
          print('[       OK ] ' .. testCase.name .. '.' .. name)
        else 
          print('[  FAILURE ] ' .. testCase.name .. '.' .. name .. ' | ' .. err)
        end
      end
    end
  end
end

function test()
  EXPECT_TRUE(true)
  EXPECT_TRUE(1 == 1)
  EXPECT_FALSE(false)
  EXPECT_FALSE(1 ~= 1)

  EXPECT_EQ(nil, nil)
  EXPECT_EQ(true, true)
  EXPECT_EQ(false, false)
  EXPECT_EQ(1, 1)
  EXPECT_EQ("hello, world", "hello, world")
  EXPECT_EQ(next, next)
  local t = {a=100, b="hello"}
  EXPECT_EQ(t, t)

  EXPECT_NE(1, 2)
  EXPECT_NE(true, false)
  EXPECT_NE(false, true)
  EXPECT_NE("hello", "world")
  EXPECT_NE(next, print)
  EXPECT_NE({a=100, b="hello"}, {a=100})
  EXPECT_NE({b="hello"}, {a=100, b="hello"})
  EXPECT_NE({a=100, b="hello"}, {c=100, d="hello"})
  EXPECT_NE({1, 2}, {1, 2, 3})
  EXPECT_NE({1, 2, 3}, {2, 3})
  EXPECT_NE({1, 2}, {2, 3})

  EXPECT_THAT({1, 2, 3}, Listwise(Equals, {1, 2, 3}))
  EXPECT_THAT({1, 2, 3}, Listwise(function(v) return Not(Equals(v)) end, {2, 4, 6}))
  EXPECT_THAT({1, 2, 3}, Not(Listwise(Equals, {1, 2, 4})))
  EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 3})))
  EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 4})))

  EXPECT_THAT({a=100, b="hello"}, Tablewise(Equals, {a=100, b="hello"}))
  EXPECT_THAT({a=100, b="hello"}, Tablewise(function(v) return Not(Equals(v)) end, {a=1000, b="goodbye"}))
  EXPECT_THAT({a=100, b="hello"}, Not(Tablewise(Equals, {a=100, b="hello", c="world"})))
  EXPECT_THAT({a=100, b="hello", c="world"}, Not(Tablewise(Equals, {a=100, b="hello"})))

  -- -- Test to ensure they fail when they get bad values
  EXPECT_FALSE(pcall(EXPECT_TRUE, false))
  EXPECT_FALSE(pcall(EXPECT_FALSE, true))

  EXPECT_FALSE(pcall(EXPECT_EQ, nil, 1))
  EXPECT_FALSE(pcall(EXPECT_EQ, true, false))
  EXPECT_FALSE(pcall(EXPECT_EQ, nil, 1))
  EXPECT_FALSE(pcall(EXPECT_EQ, false, true))
  EXPECT_FALSE(pcall(EXPECT_EQ, 1, 2))
  EXPECT_FALSE(pcall(EXPECT_EQ, "hello", "world"))
  EXPECT_FALSE(pcall(EXPECT_EQ, next, print))
  EXPECT_FALSE(pcall(EXPECT_EQ, {a=100, b="hello"}, {a=100}))
  EXPECT_FALSE(pcall(EXPECT_EQ, {b="hello"}, {a=100, b="hello"}))
  EXPECT_FALSE(pcall(EXPECT_EQ, {a=100, b="hello"}, {c=100, d="hello"}))
  EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2}, {1, 2, 3}))
  EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2, 3}, {2, 3}))
  EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2}, {2, 3}))

  EXPECT_FALSE(pcall(EXPECT_NE, nil, nil))
  EXPECT_FALSE(pcall(EXPECT_NE, true, true))
  EXPECT_FALSE(pcall(EXPECT_NE, false, false))
  EXPECT_FALSE(pcall(EXPECT_NE, 1, 1))
  EXPECT_FALSE(pcall(EXPECT_NE, "hello, world", "hello, world"))
  EXPECT_FALSE(pcall(EXPECT_NE, next, next))

  EXPECT_FALSE(pcall(EXPECT_THAT, {1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {2, 4, 65}))))

  EXPECT_FALSE(pcall(EXPECT_THAT, {7, 8, 9},
                           Listwise(function(v) return GreaterThan(v) end,
                                    {12, 2, 3})))

  EXPECT_FALSE(pcall(EXPECT_THAT, {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}},
                           Listwise(function(v) return Listwise(GreaterThanOrEqual, v) end,
                                    {{1, 2, 3}, {4, 5, 6}, {7, 8, 10}})))

end



test()