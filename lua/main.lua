require 'strict'

local from = require 'util/import'
local method = from 'util/function' : import 'Function'
local class = from 'util/class' : import 'class'

local Test = class 'Test' {
  __init = function()
    print 'hello'
  end,

  blah = method {
    function(test)
      print(test)
    end
  }
}

local t = Test()
t.blah(hello)
