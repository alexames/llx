local class_module = require 'llx.class'
local tostringf_module = require 'llx.tostringf'
local unit = require 'unit'

local class = class_module.class
local tostringf = tostringf_module.tostringf
local styles = tostringf_module.styles

_ENV = unit.create_test_env(_ENV)

TestType = class 'TestType' {
  __init = function(self)
    self.table_t = {1, 2, 3}
    self.str = 'this is a string'
    self.number = 12345
  end,

  __tostringf = function(self, formatter)
    formatter:table_cons 'TestType'{
      {'table_t', self.table_t, styles.abbrev},
      {'str', self.str},
      {'number', self.number},
    }
  end,
}

print('```')
print(tostringf(TestType(), styles.abbrev))
print('```')

--[===[

test_class 'ExpectationTest' {
  [test 'expect_equality'] = function(self)
    EXPECT_EQ(nil, nil)

    EXPECT_EQ(true, true)
    EXPECT_EQ(false, false)
    EXPECT_EQ(self.test_boolean, true)

    EXPECT_EQ(100, 100)
    EXPECT_EQ(100, self.test_integer)
    
    EXPECT_EQ('Hello, world!', 'Hello, world!')
    EXPECT_EQ('Hello, world!', self.test_string)

    -- Expect that the EXPECT_EQ test fails in these cases.
    EXPECT_ERROR(function()
      EXPECT_EQ(nil, 1)
    end)
    EXPECT_ERROR(function()
      EXPECT_EQ(true, false)
    end)
    EXPECT_ERROR(function()
      EXPECT_EQ(100, 0)
    end)
    EXPECT_ERROR(function()
      EXPECT_EQ('Hello, world!', 'Goodbye, world!')
    end)
  end,

  [test 'expect_inequality'] = function(self)
    EXPECT_NE(nil, 1)

    EXPECT_NE(true, false)
    EXPECT_NE(false, true)
    EXPECT_NE(self.test_boolean, false)

    EXPECT_NE(0, 100)
    EXPECT_NE(0, self.test_integer)
    
    EXPECT_NE('Goodbyte, world!', 'Hello, world!')
    EXPECT_NE('Goodbyte, world!', self.test_string)

    -- Expect that the EXPECT_NE test fails in these cases.
    EXPECT_ERROR(function()
      EXPECT_NE(nil, nil)
    end)
    EXPECT_ERROR(function()
      EXPECT_NE(true, true)
    end)
    EXPECT_ERROR(function()
      EXPECT_NE(100, 100)
    end)
    EXPECT_ERROR(function()
      EXPECT_NE('Hello, world!', 'Hello, world!')
    end)
  end,

  [test 'expect_true'] = function(self)
    EXPECT_TRUE(true)
    
    -- Expect that the EXPECT_NE test fail in this case.
    EXPECT_ERROR(function()
      EXPECT_TRUE(false)
    end)
    EXPECT_ERROR(function()
      EXPECT_TRUE(1)
    end)
  end,

  [test 'expect_false'] = function(self)
    EXPECT_FALSE(false)
    
    -- Expect that the EXPECT_NE test fail in this case.
    EXPECT_ERROR(function()
      EXPECT_FALSE(true)
    end)
    EXPECT_ERROR(function()
      EXPECT_FALSE(nil)
    end)
  end,

  [test 'expect_truthy'] = function(self)
    EXPECT_TRUTHY(true)
    EXPECT_TRUTHY(1)
    
    -- Expect that the EXPECT_NE test fail in this case.
    EXPECT_ERROR(function()
      EXPECT_TRUTHY(false)
    end)
    EXPECT_ERROR(function()
      EXPECT_TRUTHY(nil)
    end)
  end,

  [test 'expect_falsey'] = function(self)
    EXPECT_FALSEY(false)
    EXPECT_FALSEY(nil)
    
    -- Expect that the EXPECT_NE test fail in this case.
    EXPECT_ERROR(function()
      EXPECT_FALSEY(true)
    end)
    EXPECT_ERROR(function()
      EXPECT_FALSEY(1)
    end)
  end,

  [test 'expect_error'] = function(self)
    EXPECT_ERROR(function()
       error('error!')
    end, 'error!')

    EXPECT_ERROR(function()
       error('error!')
    end)
  end,

  [test 'expect_error_no_error'] = function(self)
    -- Verify that when a function passed to EXPECT_ERROR fails to raise the
    -- correct error the EXPECT_ERROR function fails correctly.
    local successful, exception = pcall(function()
      EXPECT_ERROR(function() end)
    end)
    EXPECT_FALSE(successful)

    -- Just check the suffix, since error messages are prefixed with a file and
    -- line number.
    EXPECT_THAT(exception, EndsWith 'expected function to raise error')
  end,

  [test 'expect_error_wrong_error'] = function(self)
    -- Verify that when a function passed to EXPECT_ERROR fails to raise the
    -- correct error the EXPECT_ERROR function fails correctly.
    local successful, exception = pcall(function()
      EXPECT_ERROR(function()
       error('actual error message!')
      end, 'expected error message!')
    end)
    EXPECT_FALSE(successful)

    -- Just check the suffix, since error messages are prefixed with a file and
    -- line number.
    EXPECT_THAT(exception, EndsWith [[
expected 
  actual error message!
to be equal to
  expected error message!]])
  end,
}

run_unit_tests()
]===]