local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local property = require 'llx.property'
local string_view = require 'llx.string_view'
local unit = require 'llx.unit'

local class = class_module.class
local StringView = string_view.StringView

_ENV = unit.create_test_env(_ENV)

-- test_string_view_methods.lua
-- Unit tests for Lua string methods via StringView

describe('StringViewStringMethodTests', function()
  it('should return byte value for first character', function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    expect(view:byte(1)).to.be_equal_to(string.byte("b"))
  end)

  it('should return byte value for second character', function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    expect(view:byte(2)).to.be_equal_to(string.byte("c"))
  end)

  it('should return byte value for third character', function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    expect(view:byte(3)).to.be_equal_to(string.byte("d"))
  end)

  it('should find pattern and return start position', function()
    local view = StringView("abcdefghi", 3, 5) -- "cdefg"
    local s, e = view:find("ef")
    expect(s).to.be_equal_to(3)
  end)

  it('should find pattern and return end position', function()
    local view = StringView("abcdefghi", 3, 5) -- "cdefg"
    local s, e = view:find("ef")
    expect(e).to.be_equal_to(4)
  end)

  it('should return correct length for view', function()
    local view = StringView("hello world", 4, 5) -- "lo wo"
    expect(view:len()).to.be_equal_to(5)
  end)

  it('should convert view to lowercase', function()
    local view = StringView("HeLLo", 1, 5)
    expect(view:lower()).to.be_equal_to("hello")
  end)

  it('should convert view to uppercase', function()
    local view = StringView("HeLLo", 1, 5)
    expect(view:upper()).to.be_equal_to("HELLO")
  end)

  it('should match pattern in view', function()
    local view = StringView("abcdefghi", 3, 4) -- "cdef"
    local result = view:match("cd")
    expect(result).to.be_equal_to("cd")
  end)

  it('should return substring from view', function()
    local view = StringView("abcdefghi", 3, 5) -- "cdefg"
    expect(view:sub(2, 4)).to.be_equal_to("def")
  end)

  it('should reverse view string', function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    expect(view:reverse()).to.be_equal_to("dcb")
  end)

  it('should repeat view string', function()
    local view = StringView("abc", 1, 3)
    expect(view:rep(2)).to.be_equal_to("abcabc")
  end)

  it('should iterate over matches using gmatch', function()
    local view = StringView("a1 b2 c3", 1, 7)
    local iter = view:gmatch("%a%d")
    local out = {}
    for v in iter do table.insert(out, v) end
    expect(table.concat(out, ",")).to.be_equal_to("a1,b2,c3")
  end)

  it('should substitute pattern using gsub', function()
    local view = StringView("a1b2c3", 1, 6)
    local s = view:gsub("%d", "x")
    expect(s).to.be_equal_to("axbxcx")
  end)

  it('should not have format method', function()
    local view = StringView("abc", 1, 3)
    expect(view.format).to.be_nil()
  end)

  it('should not have dump method', function()
    local view = StringView("abc", 1, 3)
    expect(view.dump).to.be_nil()
  end)

  it('should not have pack method', function()
    local view = StringView("abc", 1, 3)
    expect(view.pack).to.be_nil()
  end)

  it('should not have packsize method', function()
    local view = StringView("abc", 1, 3)
    expect(view.packsize).to.be_nil()
  end)

  it('should not have unpack method', function()
    local view = StringView("abc", 1, 3)
    expect(view.unpack).to.be_nil()
  end)

  it('should not have char method', function()
    local view = StringView("abc", 1, 3)
    expect(view.char).to.be_nil()
  end)
end)

unit.run_unit_tests()
