
Mock = class 'Mock' {
  __init = function(self)
    self._call_spec = nil
    self._call_count = 0
    self._call_count_expectation = nil
  end;

  call_spec = function(self, call_list)
    self._call_spec = call_list
    return self
  end;

  call_count = function(self, expectation)
    self._call_count_expectation = expectation
    return self
  end;

  __call = function(self, ...)
    self._call_count = self._call_count + 1
    local current_call_spec = self._call_spec[self._call_count]
    if current_call_spec then
      local expected_args = current_call_spec.expected_args
      if expected_args then
        local arguments = {...}
        for i, predicate in ipairs(expected_args) do
          EXPECT_THAT(arguments[i], predicate, 'argument #' .. i)
        end
      end
      local return_values = current_call_spec.return_values
      if return_values then
        return table.unpack(return_values)
      end
    end
  end;

  __close = function(self)
    expectation = self._call_count_expectation
    if expectation then
      EXPECT_THAT(self._call_count, expectation, 'call count')
    end
  end;
}