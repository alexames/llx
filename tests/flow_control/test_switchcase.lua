local unit = require 'llx.unit'
local llx = require 'llx'

-- switchcase.lua sets globals: default, switch, case, type_switch
-- We need to require it before changing _ENV so the globals are accessible.
require 'llx.flow_control.switchcase'

_ENV = unit.create_test_env(_ENV)

describe('switch', function()
  it('should dispatch to the matching case', function()
    local result = nil
    switch(1) {
      [1] = function(v) result = 'one' end,
      [2] = function(v) result = 'two' end,
    }
    expect(result).to.be_equal_to('one')
  end)

  it('should dispatch to the second case', function()
    local result = nil
    switch(2) {
      [1] = function(v) result = 'one' end,
      [2] = function(v) result = 'two' end,
    }
    expect(result).to.be_equal_to('two')
  end)

  it('should pass the value to the handler', function()
    local received = nil
    switch(42) {
      [42] = function(v) received = v end,
    }
    expect(received).to.be_equal_to(42)
  end)

  it('should dispatch to the default case when no match', function()
    local result = nil
    switch(99) {
      [1] = function(v) result = 'one' end,
      [2] = function(v) result = 'two' end,
      [default] = function(v) result = 'default' end,
    }
    expect(result).to.be_equal_to('default')
  end)

  it('should pass the value to the default handler', function()
    local received = nil
    switch(99) {
      [default] = function(v) received = v end,
    }
    expect(received).to.be_equal_to(99)
  end)

  it('should do nothing when no match and no default', function()
    local result = 'unchanged'
    switch(99) {
      [1] = function(v) result = 'one' end,
      [2] = function(v) result = 'two' end,
    }
    expect(result).to.be_equal_to('unchanged')
  end)

  it('should work with string keys', function()
    local result = nil
    switch('hello') {
      ['hello'] = function(v) result = 'greeting' end,
      ['bye'] = function(v) result = 'farewell' end,
    }
    expect(result).to.be_equal_to('greeting')
  end)

  it('should prefer exact match over default', function()
    local result = nil
    switch(1) {
      [1] = function(v) result = 'exact' end,
      [default] = function(v) result = 'default' end,
    }
    expect(result).to.be_equal_to('exact')
  end)

  it('should work with boolean keys', function()
    local result = nil
    switch(true) {
      [true] = function(v) result = 'true_branch' end,
      [false] = function(v) result = 'false_branch' end,
    }
    expect(result).to.be_equal_to('true_branch')
  end)
end)

describe('default', function()
  it('should be a table', function()
    expect(type(default)).to.be_equal_to('table')
  end)

  it('should be usable as a table key', function()
    local t = { [default] = 'fallback' }
    expect(t[default]).to.be_equal_to('fallback')
  end)
end)

describe('case', function()
  it('should return a table with index and value fields', function()
    local result = case('SomeType')
    expect(result.value).to.be_equal_to('SomeType')
    expect(type(result.index)).to.be_equal_to('number')
  end)

  it('should increment index for each call', function()
    local c1 = case('A')
    local c2 = case('B')
    expect(c2.index).to.be_greater_than(c1.index)
  end)

  it('should store a table as the value', function()
    local my_type = { name = 'MyType' }
    local result = case(my_type)
    expect(result.value).to.be_equal_to(my_type)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
