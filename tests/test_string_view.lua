local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local property = require 'llx.property'
local string_view = require 'llx.string_view'
local unit = require 'unit'

local test_class = unit.test_class
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_THAT = unit.EXPECT_THAT
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE
local Equals = unit.Equals

local test_class = unit.test_class
local class = class_module.class
local StringView = string_view.StringView

-- test_string_view_methods.lua
-- Unit tests for Lua string methods via StringView

unit.test_class 'StringViewStringMethodTests' {
  [test 'string.byte'] = function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    EXPECT_EQ(view:byte(1), string.byte("b"))
    EXPECT_EQ(view:byte(2), string.byte("c"))
    EXPECT_EQ(view:byte(3), string.byte("d"))
  end,

  [test 'string.find'] = function()
    local view = StringView("abcdefghi", 3, 5) -- "cdefg"
    local s, e = view:find("ef")
    EXPECT_EQ(s, 3)
    EXPECT_EQ(e, 4)
  end,

  [test 'string.len'] = function()
    local view = StringView("hello world", 4, 5) -- "lo wo"
    EXPECT_EQ(view:len(), 5)
  end,

  [test 'string.lower'] = function()
    local view = StringView("HeLLo", 1, 5)
    EXPECT_EQ(view:lower(), "hello")
  end,

  [test 'string.upper'] = function()
    local view = StringView("HeLLo", 1, 5)
    EXPECT_EQ(view:upper(), "HELLO")
  end,

  [test 'string.match'] = function()
    local view = StringView("abcdefghi", 3, 4) -- "cdef"
    local result = view:match("cd")
    EXPECT_EQ(result, "cd")
  end,

  [test 'string.sub'] = function()
    local view = StringView("abcdefghi", 3, 5) -- "cdefg"
    EXPECT_EQ(view:sub(2, 4), "def")
  end,

  [test 'string.reverse'] = function()
    local view = StringView("abcdef", 2, 3) -- "bcd"
    EXPECT_EQ(view:reverse(), "dcb")
  end,

  [test 'string.rep'] = function()
    local view = StringView("abc", 1, 3)
    EXPECT_EQ(view:rep(2), "abcabc")
  end,

  [test 'string.gmatch'] = function()
    local view = StringView("a1 b2 c3", 1, 7)
    local iter = view:gmatch("%a%d")
    local out = {}
    for v in iter do table.insert(out, v) end
    EXPECT_EQ(table.concat(out, ","), "a1,b2,c3")
  end,

  [test 'string.gsub'] = function()
    local view = StringView("a1b2c3", 1, 6)
    local s = view:gsub("%d", "x")
    EXPECT_EQ(s, "axbxcx")
  end,

  [test 'unsupported string functions should not exist'] = function()
    local view = StringView("abc", 1, 3)
    EXPECT_EQ(view.format, nil)
    EXPECT_EQ(view.dump, nil)
    EXPECT_EQ(view.pack, nil)
    EXPECT_EQ(view.packsize, nil)
    EXPECT_EQ(view.unpack, nil)
    EXPECT_EQ(view.char, nil)
  end,
}

unit.run_unit_tests()
