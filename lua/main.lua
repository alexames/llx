
class, test = table.unpack(require 'lx/class', nil, nil)
method = require 'lx/method'
types = require 'types/basic_types'


local Foo = class 'Foo' {
  __init = function(self)

  end
}

local Bar = class 'Bar' : extends(Foo) {
  __init = function(self)
  end
}


local f = Foo()

double = method{
  types = {
    args = {types.Union{Foo, number}},
    returns = {number}
  },
  function (i)
    return 100
  end
}

print(double(Foo()))
print(double(100))

test()
