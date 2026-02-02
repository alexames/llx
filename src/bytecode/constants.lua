local i = 1
local size_of_integer = 0
repeat
  size_of_integer = size_of_integer + 8
  i = i << 8
until i == 0

return {
  size_of_instruction = 4,
  size_of_integer = size_of_integer,
  size_of_number = size_of_integer,
}