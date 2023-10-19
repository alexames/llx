require 'lx'
require 'unit'

test_class 'main' {
  [test('foo')] = function()
  end
}

test_class 'more' {
  [test('foo')] = function()
    return false
  end;
  [test('bar')] = function()
    return false
  end;
  [test('baz')] = function()
    error('something went wrong, whoops')
  end;
  [test('qux')] = function()
    return false
  end;
}

run_unit_tests()