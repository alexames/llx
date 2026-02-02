local unit = require 'llx.unit'
local llx = require 'llx'
local check_arguments_module = require 'llx.check_arguments'
require 'llx.types'
require 'llx.schema'

local check_arguments = check_arguments_module.check_arguments
local List = llx.List
local Set = llx.Set
local Schema = llx.Schema
local Number = llx.Number
local Integer = llx.Integer
local Float = llx.Float
local Boolean = llx.Boolean
local Table = llx.Table
local String = llx.String

_ENV = unit.create_test_env(_ENV)

describe('check_arguments', function()
  describe('numbers', function()
    it('should succeed with valid numbers', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, 2, 3)
      expect(success).to.be_true()
    end)

    it('should fail when first argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, {}, 2, 3)
      expect(success).to.be_false()
    end)

    it('should fail when middle argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, {}, 3)
      expect(success).to.be_false()
    end)

    it('should fail when last argument is invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, 1, 2, {})
      expect(success).to.be_false()
    end)

    it('should fail when all arguments are invalid', function()
      local success = pcall(function(num1, num2, num3)
        check_arguments{num1=Number, num2=Number, num3=Number}
      end, {}, {}, {})
      expect(success).to.be_false()
    end)
  end)

  describe('integers and numbers', function()
    it('should succeed when last is integer', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2.0, 3)
      expect(success).to.be_true()
    end)

    it('should succeed when last is float', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2.0, 3.0)
      expect(success).to.be_true()
    end)

    it('should fail when float expected but integer provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1, 2, 3)
      expect(success).to.be_false()
    end)

    it('should fail when integer expected but float provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, 1.0, 2.0, 3)
      expect(success).to.be_false()
    end)

    it('should fail when wrong type provided', function()
      local success = pcall(function (i, f, n)
        check_arguments{i=Integer, f=Float, n=Number}
      end, {}, {}, 3)
      expect(success).to.be_false()
    end)
  end)

  describe('boolean', function()
    it('should succeed with true', function()
      local success = pcall(function(b)
        check_arguments{b=Boolean}
      end, true)
      expect(success).to.be_true()
    end)

    it('should succeed with false', function()
      local success = pcall(function(b)
        check_arguments{b=Boolean}
      end, false)
      expect(success).to.be_true()
    end)
  end)

  describe('table', function()
    it('should succeed with valid table', function()
      local success = pcall(function(t)
        check_arguments{t=Table}
      end, {})
      expect(success).to.be_true()
    end)

    it('should fail with non-table', function()
      local success = pcall(function(t)
        check_arguments{t=Table}
      end, true)
      expect(success).to.be_false()
    end)
  end)

  describe('list', function()
    it('should succeed with valid list', function()
      local success = pcall(function(t)
        check_arguments{t=List}
      end, List{})
      expect(success).to.be_true()
    end)

    it('should fail with table instead of list', function()
      local success = pcall(function(t)
        check_arguments{t=List}
      end, {})
      expect(success).to.be_false()
    end)
  end)

  describe('schema', function()
    it('should succeed with number schema and valid number', function()
      local schema = Schema{type=Number}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, 1)
      expect(success).to.be_true()
    end)

    it('should fail with number schema and invalid value', function()
      local schema = Schema{type=Number}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, '')
      expect(success).to.be_false()
    end)

    it('should succeed with table schema and valid table', function()
      local schema = Schema{type=Table}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, {})
      expect(success).to.be_true()
    end)

    it('should succeed with table schema with properties', function()
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
      expect(success).to.be_true()
    end)

    it('should fail with table schema and non-table', function()
      local schema = Schema{type=Table}
      local success = pcall(function(t)
        check_arguments{t=schema}
      end, 1)
      expect(success).to.be_false()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
