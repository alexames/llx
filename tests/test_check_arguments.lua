local unit = require 'unit'
require 'llx/src/check_arguments'
require 'llx/src/types'
require 'llx/src/schema'

test_class 'check_arguments' {
  [test 'numbers' - 'success'] = function()
    local success = pcall(function(num1, num2, num3)
      check_arguments{num1=Number, num2=Number, num3=Number}
    end, 1, 2, 3)
    EXPECT_TRUE(success)
  end,
  [test 'numbers' - 'fail' - 'first'] = function()
    local success = pcall(function(num1, num2, num3)
      check_arguments{num1=Number, num2=Number, num3=Number}
    end, {}, 2, 3)
    EXPECT_FALSE(success)
  end,
  [test 'numbers' - 'fail' - 'middle'] = function()
    local success = pcall(function(num1, num2, num3)
      check_arguments{num1=Number, num2=Number, num3=Number}
    end, 1, {}, 3)
    EXPECT_FALSE(success)
  end,
  [test 'numbers' - 'fail' - 'last'] = function()
    local success = pcall(function(num1, num2, num3)
      check_arguments{num1=Number, num2=Number, num3=Number}
    end, 1, 2, {})
    EXPECT_FALSE(success)
  end,
  [test 'numbers' - 'fail' - 'all'] = function()
    local success = pcall(function(num1, num2, num3)
      check_arguments{num1=Number, num2=Number, num3=Number}
    end, {}, {}, {})
    EXPECT_FALSE(success)
  end,

  [test 'integers and numbers' - 'success' - 'last is integer'] = function()

    local success = pcall(function (i, f, n)
      check_arguments{i=Integer, f=Float, n=Number}
    end, 1, 2.0, 3)
    EXPECT_TRUE(success)
  end,
  [test 'integers and numbers' - 'success' - 'last is float'] = function()
    local success = pcall(function (i, f, n)
      check_arguments{i=Integer, f=Float, n=Number}
    end, 1, 2.0, 3.0)
    EXPECT_TRUE(success)
  end,

  [test 'integers and numbers' - 'failure' - 'float expected'] = function()
    local success = pcall(function (i, f, n)
      check_arguments{i=Integer, f=Float, n=Number}
    end, 1, 2, 3)
    EXPECT_FALSE(success)
  end,
  [test 'integers and numbers' - 'failure' - 'integer expected'] = function()
    local success = pcall(function (i, f, n)
      check_arguments{i=Integer, f=Float, n=Number}
    end, 1.0, 2.0, 3)
    EXPECT_FALSE(success)
  end,
  [test 'integers and numbers' - 'failure' - 'wrong type'] = function()
    local success = pcall(function (i, f, n)
      check_arguments{i=Integer, f=Float, n=Number}
    end, {}, {}, 3)
    EXPECT_FALSE(success)
  end,

  [test 'boolean' - 'true' - 'success'] = function()
    local success = pcall(function(b)
      check_arguments{b=Boolean}
    end, true)
    EXPECT_TRUE(success)
  end,
  [test 'boolean' - 'false' - 'success'] = function()
    local success = pcall(function(b)
      check_arguments{b=Boolean}
    end, false)
    EXPECT_TRUE(success)
  end,

  [test 'table' - 'success'] = function()
    local success = pcall(function(t)
      check_arguments{t=Table}
    end, {})
    EXPECT_TRUE(success)
  end,
  [test 'table' - 'failure'] = function()
    local success = pcall(function(t)
      check_arguments{t=Table}
    end, true)
    EXPECT_FALSE(success)
  end,

  [test 'list' - 'success'] = function()
    local success = pcall(function(t)
      check_arguments{t=List}
    end, List{})
    EXPECT_TRUE(success)
  end,
  [test 'list' - 'failure' - 'table'] = function()
    local success = pcall(function(t)
      check_arguments{t=List}
    end, {})
    EXPECT_FALSE(success)
  end,

  [test 'schema' - 'number' - 'success'] = function()
    local schema = Schema{type=Number}
    local success = pcall(function(t)
      check_arguments{t=schema}
    end, 1)
    EXPECT_TRUE(success)
  end,

  [test 'schema' - 'number' - 'failure'] = function()
    local schema = Schema{type=Number}
    local success = pcall(function(t)
      check_arguments{t=schema}
    end, '')
    EXPECT_FALSE(success)
  end,

  [test 'schema' - 'table' - 'success'] = function()
    local schema = Schema{type=Table}
    local success = pcall(function(t)
      check_arguments{t=schema}
    end, {})
    EXPECT_TRUE(success)
  end,
  [test 'schema' - 'table with properties' - 'success'] = function()
    local schema = Schema{
      type=Table,
      properties={
        b={type=Boolean},
        n={type=Number},
        s={type=String},
        t={
          type=Table,
          properties={
            l={type=List},
            s={type=Set},
         },
        },
      },
    }
    local success = pcall(function(arg)
      check_arguments{arg=schema}
    end, {b=true, n=10, s='', t={l=List{1,2,3},s=Set{'a', 'b', 'c'}}})
    EXPECT_TRUE(success)
  end,

  [test 'schema' - 'table' - 'failure'] = function()
    local schema = Schema{type=Table}
    local success = pcall(function(t)
      check_arguments{t=schema}
    end, 1)
    EXPECT_FALSE(success)
  end,
}

if main_file() then
  unit.run_unit_tests()
end
