require 'lx/base'

local test_index = 0
function test(name)
  test_index = test_index + 1
  return {index = test_index, name=name, __istest=true}
end

local function is_test(t)
  return Table:isinstance(t) and t.__istest
end

local Test = class 'Test' {
  setup = noop;
  teardown = noop;

  __init = function(self)
    self._tests = self:gather_tests()
    self._name = getmetatable(self).__name or '<name>'
  end;

  tests = function(self) return self._tests end;
  name = function(self) return self._name end;

  gather_tests = function(self)
    -- Convert this to a List
    local result = Table()
    for key, testfunc in pairs(getmetatable(self)) do
      if is_test(key) then
        result:insert({index=key.index, name=key.name, func=testfunc})
      end
    end
    result:sort(function(a, b) return a.index < b.index end)
    return result
  end;

  run_test = function(self, func)
    self:setup()
    local successful, err = pcall(func)
    self:teardown()
    return successful, err
  end;

  run_tests = function(self, printer)
    printer.class_preamble(self)
    local failure_count = 0
    for i, test in pairs(self._tests) do
      printer.test_begin(self, test.name)
      successful, err = self:run_test(test.func)
      if not successful then
        failure_count = failure_count + 1
        -- failure_list:insert(self._name .. '.' .. name)
      end
      printer.test_end(self, test.name, successful)
    end
    printer.class_conclusion(self, failure_count)
    return failure_count, #self._tests
  end;
}

return {
  Test=Test,
}
