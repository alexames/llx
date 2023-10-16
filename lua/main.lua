require 'lx/unit'

TestCase 'main' {
  test_foo = function()
  end
}

TestCase 'more' {
  test_foo = function()
    return false
  end;
  test_bar = function()
    return false
  end;
  test_baz = function()
    error('something went wrong, whoops')
  end;
  test_qux = function()
    return false
  end;
}
