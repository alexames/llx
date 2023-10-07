require 'class'

function EXPECT_THAT(actual, condition)
  result, message = condition(actual)
  if not result then
    error(message)
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

function subsetOf(table1, table2, visited)
  if visited == nil then
    visited = {}
  end
  for key1, value1 in pairs(table1) do
    local value2 = table2[key1]
    if (value2 == nil 
        or not valuesAreEqual(value1, value2, visited)) then
      return false
    end
  end
  return true
end

function valuesAreEqual(table1, table2, visited)
  if visited == nil then
    visited = {}
  end

  local type1 = type(table1)
  local type2 = type(table2)
  if type1 ~= type2 then return false end

  -- non-table types can be directly compared
  if type1 ~= 'table' and type2 ~= 'table' then return table1 == table2 end
  
  -- as well as tables which have the metamethod __eq
  local metatable = getmetatable(table1)
  if metatable and metatable.__eq then return table1 == table2 end

  if visited[table1] or visited[table2] then
    error("recursive tables not supported")
  end
  visited[table1] = true
  visited[table2] = true

  return subsetOf(table1, table2, visited) 
         and subsetOf(table2, table1, visited)
end

function Not(funcToNegate)
  return function(actual)
    result, message = funcToNegate(actual, true)
    return not result, message
  end
end

function toBoolean(value)
  if value then return true else return false end
end

function Equals(expectation)
  return function(actual, negate)
    negate = toBoolean(negate)

    local result = valuesAreEqual(expectation, actual)
    local message = nil
    if result == negate then
      local messageOperation
      if negate then
        messageOperation = "inequality"
      else
        messageOperation = "equality"
      end
      message = "expected " .. messageOperation .. " between expected value\n  "
                .. valueToString(expectation) 
                .. "\nand actual value\n  "
                .. valueToString(actual)
    end
    return result, message
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
  EXPECT_EQ({a=100, b="hello"}, {a=100, b="hello"})
  EXPECT_EQ({1, 2, 3}, {1, 2, 3})

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

  -- Test to ensure they fail when they get bad values
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
  EXPECT_FALSE(pcall(EXPECT_NE, {1, 2, 3}, {1, 2, 3}))

  -- Recursive tables should always fail.
  local recursiveTable = {}
  recursiveTable.a = recursiveTable
  EXPECT_FALSE(pcall(EXPECT_EQ, recursiveTable, recursiveTable))
  EXPECT_FALSE(pcall(EXPECT_NE, recursiveTable, recursiveTable))

end

test()