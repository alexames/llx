local unit = require 'llx.unit'
local llx = require 'llx'
local hash = require 'llx.hash'

_ENV = unit.create_test_env(_ENV)

describe('hash', function()
  describe('hash_nil', function()
    it('should return a number when hashing nil', function()
      local result = hash.hash(nil)
      expect(result).to.be_a('number')
    end)

    it('should be deterministic for nil', function()
      expect(hash.hash(nil)).to.be_equal_to(hash.hash(nil))
    end)
  end)

  describe('hash_boolean', function()
    it('should return a number for true', function()
      expect(hash.hash(true)).to.be_a('number')
    end)

    it('should return a number for false', function()
      expect(hash.hash(false)).to.be_a('number')
    end)

    it('should be deterministic for true', function()
      expect(hash.hash(true)).to.be_equal_to(hash.hash(true))
    end)

    it('should be deterministic for false', function()
      expect(hash.hash(false)).to.be_equal_to(hash.hash(false))
    end)

    it('should produce different hashes for true and false', function()
      expect(hash.hash(true)).to_not.be_equal_to(hash.hash(false))
    end)
  end)

  describe('hash_number', function()
    it('should return a number', function()
      expect(hash.hash(42)).to.be_a('number')
    end)

    it('should be deterministic', function()
      expect(hash.hash(42)).to.be_equal_to(hash.hash(42))
    end)

    it('should produce different hashes for different numbers', function()
      expect(hash.hash(1)).to_not.be_equal_to(hash.hash(2))
    end)

    it('should produce different hashes for 0 and 1', function()
      expect(hash.hash(0)).to_not.be_equal_to(hash.hash(1))
    end)

    it('should produce different hashes for positive and negative', function()
      expect(hash.hash(5)).to_not.be_equal_to(hash.hash(-5))
    end)

    it('should produce different hashes for integer and float '
      .. 'with same floor', function()
      expect(hash.hash(1)).to_not.be_equal_to(hash.hash(1.5))
    end)

    it('should produce different hashes for distinct floats', function()
      expect(hash.hash(0.1)).to_not.be_equal_to(hash.hash(0.2))
    end)

    it('should produce same hash for integer and equivalent float', function()
      expect(hash.hash(1)).to.be_equal_to(hash.hash(1.0))
    end)
  end)

  describe('hash_string', function()
    it('should return a number', function()
      expect(hash.hash('hello')).to.be_a('number')
    end)

    it('should be deterministic', function()
      expect(hash.hash('hello')).to.be_equal_to(hash.hash('hello'))
    end)

    it('should produce different hashes for different strings', function()
      expect(hash.hash('hello')).to_not.be_equal_to(hash.hash('world'))
    end)

    it('should produce different hashes for empty and '
      .. 'non-empty strings', function()
      expect(hash.hash('')).to_not.be_equal_to(hash.hash('a'))
    end)

    it('should be deterministic for empty string', function()
      expect(hash.hash('')).to.be_equal_to(hash.hash(''))
    end)

    it('should produce different hashes for strings that '
      .. 'differ by one character', function()
      expect(hash.hash('abc')).to_not.be_equal_to(hash.hash('abd'))
    end)
  end)

  describe('hash_table', function()
    it('should return a number for an empty table', function()
      expect(hash.hash({})).to.be_a('number')
    end)

    it('should be deterministic for empty tables', function()
      expect(hash.hash({})).to.be_equal_to(hash.hash({}))
    end)

    it('should be deterministic for tables with the same content', function()
      local h1 = hash.hash({a = 1, b = 2})
      local h2 = hash.hash({a = 1, b = 2})
      expect(h1).to.be_equal_to(h2)
    end)

    it('should produce different hashes for tables with '
      .. 'different values', function()
      local h1 = hash.hash({a = 1})
      local h2 = hash.hash({a = 2})
      expect(h1).to_not.be_equal_to(h2)
    end)

    it('should produce different hashes for tables with '
      .. 'different keys', function()
      local h1 = hash.hash({a = 1})
      local h2 = hash.hash({b = 1})
      expect(h1).to_not.be_equal_to(h2)
    end)

    it('should be order-independent (keys are sorted internally)', function()
      local h1 = hash.hash({x = 10, y = 20, z = 30})
      local h2 = hash.hash({z = 30, x = 10, y = 20})
      expect(h1).to.be_equal_to(h2)
    end)

    it('should handle tables with numeric keys', function()
      local h1 = hash.hash({[1] = 'a', [2] = 'b'})
      local h2 = hash.hash({[1] = 'a', [2] = 'b'})
      expect(h1).to.be_equal_to(h2)
    end)

    it('should handle tables with a single boolean key', function()
      local h1 = hash.hash({[true] = 1})
      local h2 = hash.hash({[true] = 1})
      expect(h1).to.be_equal_to(h2)
    end)

    it('should produce different hashes for different boolean keys', function()
      local h1 = hash.hash({[true] = 1})
      local h2 = hash.hash({[false] = 1})
      expect(h1).to_not.be_equal_to(h2)
    end)

    it('should handle nested tables deterministically', function()
      local h1 = hash.hash({inner = {a = 1}})
      local h2 = hash.hash({inner = {a = 1}})
      expect(h1).to.be_equal_to(h2)
    end)

    it('should not crash when hashing a table with table keys', function()
      local inner1 = {x = 1}
      local inner2 = {x = 2}
      local t = {[inner1] = 'a', [inner2] = 'b'}
      expect(function() hash.hash(t) end).to_not.throw()
    end)
  end)

  describe('hash across types', function()
    it('should produce different hashes for number and '
      .. 'string of same value', function()
      expect(hash.hash(1)).to_not.be_equal_to(hash.hash('1'))
    end)

    it('should produce different hashes for number 1 '
      .. 'and boolean true', function()
      expect(hash.hash(1)).to_not.be_equal_to(hash.hash(true))
    end)

    it('should produce different hashes for number 0 '
      .. 'and boolean false', function()
      expect(hash.hash(0)).to_not.be_equal_to(hash.hash(false))
    end)

    it('should produce different hashes for empty string '
      .. 'and empty table', function()
      expect(hash.hash('')).to_not.be_equal_to(hash.hash({}))
    end)
  end)

  describe('custom __hash metamethod', function()
    it('should use __hash metamethod when present', function()
      local custom_hash_value = 12345
      local obj = setmetatable({}, {
        __hash = function(self, h)
          return custom_hash_value
        end,
      })
      local result = hash.hash(obj)
      expect(result).to.be_equal_to(custom_hash_value)
    end)

    it('should produce different hashes when __hash returns '
      .. 'different values', function()
      local obj1 = setmetatable({}, {
        __hash = function(self, h) return 111 end,
      })
      local obj2 = setmetatable({}, {
        __hash = function(self, h) return 222 end,
      })
      expect(hash.hash(obj1)).to_not.be_equal_to(hash.hash(obj2))
    end)

    it('should fall back to table hashing when __hash is '
      .. 'not a function', function()
      local obj = setmetatable({a = 1}, {
        __hash = 'not a function',
      })
      local plain_table = {a = 1}
      expect(hash.hash(obj)).to.be_equal_to(hash.hash(plain_table))
    end)
  end)

  describe('hash_value', function()
    it('should error on unsupported types like functions', function()
      expect(function()
        hash.hash_value(function() end, 0)
      end).to.throw()
    end)
  end)

  describe('individual hash functions', function()
    it('hash_integer should apply FNV-1a step', function()
      local result = hash.hash_integer(42, 0)
      expect(result).to.be_a('number')
    end)

    it('hash_nil should return hash unchanged', function()
      local input_hash = 12345
      expect(hash.hash_nil(nil, input_hash)).to.be_equal_to(input_hash)
    end)

    it('hash_boolean should hash true as 1 and false as 0', function()
      local base = 12345
      local hash_true = hash.hash_boolean(true, base)
      local hash_false = hash.hash_boolean(false, base)
      expect(hash_true).to_not.be_equal_to(hash_false)
      expect(hash_true).to.be_equal_to(hash.hash_integer(1, base))
      expect(hash_false).to.be_equal_to(hash.hash_integer(0, base))
    end)

    it('hash_number should delegate to hash_integer', function()
      local base = 99999
      expect(hash.hash_number(42, base)).to.be_equal_to(
        hash.hash_integer(42, base))
    end)

    it('hash_string should hash each byte', function()
      local base = 0
      local h1 = hash.hash_string('a', base)
      local h2 = hash.hash_string('b', base)
      expect(h1).to_not.be_equal_to(h2)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
