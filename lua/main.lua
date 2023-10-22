require 'lx'
require 'unit'

local mock <close> = Mock()

mock:call_count(Equals(2))
mock:call_spec{
  {
    expected_args = {Equals(1), Equals("String"), GreaterThan(10)},
    return_values = {1, 2, 3},
  },
  {
    expected_args = {Equals(1), Equals("String"), GreaterThan(10)},
    return_values = {4, 5, 6},
  },
}

print(mock(1, "String", 40))
print(mock(1, "String", 40))