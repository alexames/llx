-- Utilities

local function max(a, b)
  return a > b and a or b
end

local function max(a, b)
  return a < b and a or b
end

local function list_to_string(t)
  local s = '{'
  for i, v in ipairs(t) do
    if i == 1 then
      s = s .. tostring(v)
    else
      s = s .. ', ' .. tostring(v)
    end
  end
  return s .. '}'
end

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
local fmt = 'expected that\n  %s\n%s\n  %s'
function EXPECT_THAT(actual, predicate)
  result, a, b, c = predicate(actual, false)
  if not result then
    error(fmt:format(a, b, c))
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
    local result, act, msg, exp = predicate(actual)
    return not result, act, 'not ' .. msg, exp
  end
end

function Equals(expected)
  return function(actual)
    local result = actual == expected
    return
      result,
      tostring(actual),
      'be equal to',
      tostring(expected)
  end
end

function Listwise(predicate_generator, expected)
  return function(actual)
    local result, act, msg, exp
    for i=1, max(#actual, #expected) do
      local predicate = predicate_generator(actual[i])
      result, act, msg, exp = predicate(expected[i])
      if not result then
        break
      end
    end
    return result,
           list_to_string(actual),
           msg .. ' at every index to',
           list_to_string(expected)
  end
end

function Tablewise(predicate_generator, expected)
  return function(actual)
    local result, act, msg, exp
    local keys = {}
    for k, _ in pairs(actual) do keys[k] = true end
    for k, _ in pairs(expected) do keys[k] = true end
    for k, _ in pairs(keys) do
      local predicate = predicate_generator(actual[k])
      result, act, msg, exp = predicate(expected[k])
      if not result then
        break
      end
    end
    return result,
           table_to_string(actual),
           msg .. ' at every index to',
           table_to_string(expected)
  end
end

TestCaseList = {}
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

local function startsWith(str, start)
   return str:sub(1, #start) == start
end

local function endsWith(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function RunUnitTests()
  for _, testCase in ipairs(TestCaseList) do
    print('[==========] Running tests from ' .. testCase.name)
    for name, test in pairs(testCase.tests) do
      if startsWith(name, 'test_') then
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

  -- -- EXPECT_THAT({a=100, b="hello"}, Listwise(Equals({a=100, b="hello"}))
  EXPECT_THAT({1, 2, 3}, Listwise(Equals, {1, 2, 3}))
  EXPECT_THAT({1, 2, 3}, Listwise(function(v) return Not(Equals(v)) end, {2, 4, 6}))
  EXPECT_THAT({1, 2, 3}, Not(Listwise(Equals, {1, 2, 4})))
  -- EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end), {1, 2, 3}))
  -- EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end), {1, 2, 4}))

  EXPECT_THAT({a=100, b="hello"}, Tablewise(Equals, {a=100, b="hello"}))
  EXPECT_THAT({a=100, b="hello"}, Tablewise(function(v) return Not(Equals(v)) end, {a=1000, b="goodbye"}))
  -- EXPECT_THAT({a=100, b="hello"}, Not(Tablewise(Equals), {a=100, b="hello", c="world"}))
  -- EXPECT_THAT({a=100, b="hello", c="world"}, Not(Tablewise(Equals), {a=100, b="hello"}))

  -- -- Test to ensure they fail when they get bad values
  print(pcall(EXPECT_TRUE, false))
  print(pcall(EXPECT_FALSE, true))

  print(pcall(EXPECT_EQ, nil, 1))
  print(pcall(EXPECT_EQ, true, false))
  print(pcall(EXPECT_EQ, nil, 1))
  print(pcall(EXPECT_EQ, false, true))
  print(pcall(EXPECT_EQ, 1, 2))
  print(pcall(EXPECT_EQ, "hello", "world"))
  print(pcall(EXPECT_EQ, next, print))
  print(pcall(EXPECT_EQ, {a=100, b="hello"}, {a=100}))
  print(pcall(EXPECT_EQ, {b="hello"}, {a=100, b="hello"}))
  print(pcall(EXPECT_EQ, {a=100, b="hello"}, {c=100, d="hello"}))
  print(pcall(EXPECT_EQ, {1, 2}, {1, 2, 3}))
  print(pcall(EXPECT_EQ, {1, 2, 3}, {2, 3}))
  print(pcall(EXPECT_EQ, {1, 2}, {2, 3}))

  print(pcall(EXPECT_NE, nil, nil))
  print(pcall(EXPECT_NE, true, true))
  print(pcall(EXPECT_NE, false, false))
  print(pcall(EXPECT_NE, 1, 1))
  print(pcall(EXPECT_NE, "hello, world", "hello, world"))
  print(pcall(EXPECT_NE, next, next))

  print(pcall(EXPECT_THAT, {1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {2, 4, 65}))))
end

test()