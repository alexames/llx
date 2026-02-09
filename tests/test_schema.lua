local unit = require 'llx.unit'
local llx = require 'llx'

local matches_schema = llx.matches_schema
local Schema = llx.Schema
local Number = llx.Number
local String = llx.String
local Boolean = llx.Boolean
local Table = llx.Table

_ENV = unit.create_test_env(_ENV)

describe('Schema', function()
  describe('construction', function()
    it('should create a schema with a type field', function()
      local schema = Schema { type = Number }
      expect(schema.type).to.be_equal_to(Number)
    end)

    it('should set __name from title if provided', function()
      local schema = Schema { type = Number, title = 'MyNumber' }
      expect(schema.__name).to.be_equal_to('MyNumber')
    end)

    it('should default __name to Schema when no title is given', function()
      local schema = Schema { type = Number }
      expect(schema.__name).to.be_equal_to('Schema')
    end)

    it('should use __name field if provided directly', function()
      local schema = Schema { type = Number, __name = 'DirectName' }
      expect(schema.__name).to.be_equal_to('DirectName')
    end)

    it('should have a tostring that returns __name', function()
      local schema = Schema { type = Number, title = 'Age' }
      expect(tostring(schema)).to.be_equal_to('Age')
    end)

    it('should add __isinstance method to the schema', function()
      local schema = Schema { type = Number }
      expect(type(schema.__isinstance)).to.be_equal_to('function')
    end)
  end)
end)

describe('matches_schema', function()
  describe('simple type validation', function()
    it('should accept a number for a Number schema', function()
      local schema = Schema { type = Number }
      expect(matches_schema(schema, 42)).to.be_true()
    end)

    it('should reject a string for a Number schema', function()
      expect(function()
        matches_schema(Schema { type = Number }, 'hello')
      end).to.throw()
    end)

    it('should accept a string for a String schema', function()
      local schema = Schema { type = String }
      expect(matches_schema(schema, 'hello')).to.be_true()
    end)

    it('should reject a number for a String schema', function()
      expect(function()
        matches_schema(Schema { type = String }, 42)
      end).to.throw()
    end)

    it('should accept a boolean for a Boolean schema', function()
      local schema = Schema { type = Boolean }
      expect(matches_schema(schema, true)).to.be_true()
    end)

    it('should accept false for a Boolean schema', function()
      local schema = Schema { type = Boolean }
      expect(matches_schema(schema, false)).to.be_true()
    end)

    it('should reject a number for a Boolean schema', function()
      expect(function()
        matches_schema(Schema { type = Boolean }, 42)
      end).to.throw()
    end)

    it('should accept a table for a Table schema', function()
      local schema = Schema { type = Table }
      expect(matches_schema(schema, {})).to.be_true()
    end)

    it('should reject a string for a Table schema', function()
      expect(function()
        matches_schema(Schema { type = Table }, 'hello')
      end).to.throw()
    end)
  end)

  describe('nothrow mode', function()
    it('should return true for matching values', function()
      local schema = Schema { type = Number }
      local result = matches_schema(schema, 42, true)
      expect(result).to.be_true()
    end)

    it('should return false for non-matching values', function()
      local schema = Schema { type = Number }
      local result = matches_schema(schema, 'hello', true)
      expect(result).to.be_false()
    end)

    it('should return an exception as second value on failure', function()
      local schema = Schema { type = Number }
      local result, exception = matches_schema(schema, 'hello', true)
      expect(result).to.be_false()
      expect(exception).to_not.be_nil()
    end)
  end)

  describe('Schema __isinstance', function()
    it('should return true for matching values via isinstance', function()
      local schema = Schema { type = Number }
      expect(llx.isinstance(42, schema)).to.be_true()
    end)

    it('should return false for non-matching values via isinstance', function()
      local schema = Schema { type = Number }
      expect(llx.isinstance('hello', schema)).to.be_false()
    end)
  end)
end)

describe('Number __validate', function()
  describe('multiple_of', function()
    it('should accept a value that is a multiple', function()
      local schema = Schema { type = Number, multiple_of = 3 }
      expect(matches_schema(schema, 9)).to.be_true()
    end)

    it('should reject a value that is not a multiple', function()
      expect(function()
        matches_schema(Schema { type = Number, multiple_of = 3 }, 7)
      end).to.throw()
    end)

    it('should accept zero as a multiple of any number', function()
      local schema = Schema { type = Number, multiple_of = 5 }
      expect(matches_schema(schema, 0)).to.be_true()
    end)
  end)

  describe('minimum', function()
    it('should accept a value greater than minimum', function()
      local schema = Schema { type = Number, minimum = 5 }
      expect(matches_schema(schema, 10)).to.be_true()
    end)

    it('should reject a value equal to minimum', function()
      -- The source uses <= so equal values are rejected
      expect(function()
        matches_schema(Schema { type = Number, minimum = 5 }, 5)
      end).to.throw()
    end)

    it('should reject a value less than minimum', function()
      expect(function()
        matches_schema(Schema { type = Number, minimum = 5 }, 3)
      end).to.throw()
    end)

    it('should error in nothrow mode for value equal to minimum due to missing global', function()
      local schema = Schema { type = Number, minimum = 5 }
      expect(function()
        matches_schema(schema, 5, true)
      end).to.throw()
    end)
  end)

  describe('maximum', function()
    it('should accept a value less than maximum', function()
      local schema = Schema { type = Number, maximum = 10 }
      expect(matches_schema(schema, 5)).to.be_true()
    end)

    it('should reject a value equal to maximum', function()
      -- The source uses >= so equal values are rejected
      expect(function()
        matches_schema(Schema { type = Number, maximum = 10 }, 10)
      end).to.throw()
    end)

    it('should reject a value greater than maximum', function()
      expect(function()
        matches_schema(Schema { type = Number, maximum = 10 }, 15)
      end).to.throw()
    end)
  end)
end)

describe('String __validate', function()
  describe('min_length', function()
    it('should accept a string at minimum length', function()
      local schema = Schema { type = String, min_length = 3 }
      expect(matches_schema(schema, 'abc')).to.be_true()
    end)

    it('should accept a string longer than minimum length', function()
      local schema = Schema { type = String, min_length = 3 }
      expect(matches_schema(schema, 'abcdef')).to.be_true()
    end)

    it('should reject a string shorter than minimum length', function()
      expect(function()
        matches_schema(Schema { type = String, min_length = 3 }, 'ab')
      end).to.throw()
    end)
  end)

  describe('max_length', function()
    it('should accept a string at maximum length', function()
      local schema = Schema { type = String, max_length = 5 }
      expect(matches_schema(schema, 'abcde')).to.be_true()
    end)

    it('should accept a string shorter than maximum length', function()
      local schema = Schema { type = String, max_length = 5 }
      expect(matches_schema(schema, 'abc')).to.be_true()
    end)

    it('should reject a string longer than maximum length', function()
      expect(function()
        matches_schema(Schema { type = String, max_length = 5 }, 'abcdef')
      end).to.throw()
    end)
  end)

  describe('pattern', function()
    it('should accept a string matching the pattern', function()
      local schema = Schema { type = String, pattern = '^%d+$' }
      expect(matches_schema(schema, '12345')).to.be_true()
    end)

    it('should reject a string not matching the pattern', function()
      expect(function()
        matches_schema(Schema { type = String, pattern = '^%d+$' }, 'abc')
      end).to.throw()
    end)

    it('should accept partial matches within the string', function()
      local schema = Schema { type = String, pattern = '%d+' }
      expect(matches_schema(schema, 'abc123def')).to.be_true()
    end)
  end)

  describe('combined constraints', function()
    it('should accept a string satisfying both min and max length', function()
      local schema = Schema { type = String, min_length = 2, max_length = 5 }
      expect(matches_schema(schema, 'abc')).to.be_true()
    end)

    it('should reject a string violating min_length even if pattern matches', function()
      expect(function()
        matches_schema(
          Schema { type = String, min_length = 5, pattern = '^%a+$' }, 'abc')
      end).to.throw()
    end)
  end)
end)

describe('Table __validate', function()
  describe('properties', function()
    it('should validate nested properties', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
          age = { type = Number },
        },
      }
      expect(matches_schema(schema, { name = 'Alice', age = 30 })).to.be_true()
    end)

    it('should reject a table with a property of wrong type', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
        },
      }
      expect(function()
        matches_schema(schema, { name = 42 })
      end).to.throw()
    end)

    it('should allow extra properties not in schema', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
        },
      }
      expect(matches_schema(schema, { name = 'Alice', extra = true })).to.be_true()
    end)

    it('should accept a table with missing optional properties', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
          age = { type = Number },
        },
      }
      expect(matches_schema(schema, { name = 'Alice' })).to.be_true()
    end)
  end)

  describe('required fields', function()
    it('should accept a table with all required fields present', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
          age = { type = Number },
        },
        required = { 'name', 'age' },
      }
      expect(matches_schema(schema, { name = 'Alice', age = 30 })).to.be_true()
    end)

    it('should reject a table missing a required field', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
          age = { type = Number },
        },
        required = { 'name', 'age' },
      }
      expect(function()
        matches_schema(schema, { name = 'Alice' })
      end).to.throw()
    end)

    it('should reject a table missing all required fields', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
        },
        required = { 'name' },
      }
      expect(function()
        matches_schema(schema, {})
      end).to.throw()
    end)

    it('should return false in nothrow mode for missing required field', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String },
        },
        required = { 'name' },
      }
      local result = matches_schema(schema, {}, true)
      expect(result).to.be_false()
    end)
  end)

  describe('nested schemas', function()
    it('should validate deeply nested properties', function()
      local schema = Schema {
        type = Table,
        properties = {
          address = {
            type = Table,
            properties = {
              city = { type = String },
              zip = { type = Number },
            },
          },
        },
      }
      expect(matches_schema(schema, {
        address = { city = 'Springfield', zip = 62701 }
      })).to.be_true()
    end)

    it('should reject deeply nested property of wrong type', function()
      local schema = Schema {
        type = Table,
        properties = {
          address = {
            type = Table,
            properties = {
              city = { type = String },
            },
          },
        },
      }
      expect(function()
        matches_schema(schema, { address = { city = 123 } })
      end).to.throw()
    end)

    it('should validate nested properties with constraints', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String, min_length = 1 },
        },
        required = { 'name' },
      }
      expect(matches_schema(schema, { name = 'Alice' })).to.be_true()
    end)

    it('should reject nested properties failing constraints', function()
      local schema = Schema {
        type = Table,
        properties = {
          name = { type = String, min_length = 5 },
        },
        required = { 'name' },
      }
      expect(function()
        matches_schema(schema, { name = 'Al' })
      end).to.throw()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
