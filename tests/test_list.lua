local unit = require 'unit'
require 'llx/src/collections/list'

test_class 'ListTest' {
  [test '__new'] = function()
    local list_table = {}
    local list = List(list_table)
    EXPECT_EQ(list_table, list)
  end,

  [test 'extend'] = function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    list_a:extend(list_b)
    EXPECT_EQ(list_a, {1, 2, 3, 4, 5, 6})
    EXPECT_EQ(list_b, {4, 5, 6})
  end,

  [test 'ivalues'] = function()
    local mock <close> = Mock()
    mock:call_count(Equals(3)):call_spec{
      {expected_args={Equals('a')}},
      {expected_args={Equals('b')}},
      {expected_args={Equals('c')}},
    }
    local list = List{'a', 'b', 'c'}
    for v in list:ivalues() do
      mock(v)
    end
  end,

  [test 'contains'] = function()
    local list = List{1, 2, 3}
    EXPECT_TRUE(list:contains(1))
    EXPECT_TRUE(list:contains(2))
    EXPECT_TRUE(list:contains(3))
    EXPECT_FALSE(list:contains(4))
  end,

  [test 'sub'] = function()
    local list = List{1, 2, 3, 4, 5, 6}
    EXPECT_EQ(list:sub(1, 3), {1, 2, 3})
    EXPECT_EQ(list:sub(1, 6, 2), {1, 3, 5})
    EXPECT_EQ(list:sub(2, 4), {2, 3, 4})
    EXPECT_EQ(list:sub(2, 6, 2), {2, 4, 6})
    EXPECT_EQ(list:sub(6, 1, -1), {6, 5, 4, 3, 2, 1})
    EXPECT_EQ(list:sub(6, 1, -2), {6, 4, 2})
    EXPECT_EQ(list:sub(1, 0), {})
    EXPECT_EQ(list:sub(0), {1, 2, 3, 4, 5, 6})
  end,

  [test 'reverse'] = function()
    local list = List{1, 2, 3, 4, 5, 6}
    local reversed_list = list:reverse()
    EXPECT_EQ(list, {1, 2, 3, 4, 5, 6})
    EXPECT_EQ(reversed_list, {6, 5, 4, 3, 2, 1})
  end,

  [test '__index'] = function()
    local list = List{1, 2, 3, 4, 5, 6}
    EXPECT_EQ(list[1], 1)
    EXPECT_EQ(list[2], 2)
    EXPECT_EQ(list[3], 3)
    EXPECT_EQ(list[-1], 6)
    EXPECT_EQ(list[-2], 5)
    EXPECT_EQ(list[-3], 4)
  end,

  [test '__index_list'] = function()
    local list = List{'a', 'b', 'c', 'd', 'e', 'f'}
    EXPECT_EQ(list[{1, 3, 5}], List{'a', 'c', 'e'})
    EXPECT_EQ(list[{5, 4, 6}], List{'e', 'd', 'f'})
    EXPECT_EQ(list[{-3, -2, -1}], List{'d', 'e', 'f'})
    EXPECT_EQ(list[{{1, 2, 3}, {2, 3, 4}, {3, 4, 5}}],
              List{List{'a', 'b', 'c'},
                   List{'b', 'c', 'd'},
                   List{'c', 'd', 'e'}})
  end,

  [test '__concat'] = function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    local concat_list = list_a .. list_b
    EXPECT_EQ(list_a, {1, 2, 3})
    EXPECT_EQ(list_b, {4, 5, 6})
    EXPECT_EQ(concat_list, {1, 2, 3, 4, 5, 6})
  end,

  [test '__mul'] = function()
    local list = List{1, 2, 3}
    local multiplied_list = list * 3
    local multiplied_list = 3 * list
    EXPECT_EQ(list, {1, 2, 3})
    EXPECT_EQ(multiplied_list, {1, 2, 3, 1, 2, 3, 1, 2, 3})
  end,

  [test 'shift right >>'] = function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    EXPECT_EQ(list >> 0, List{'a', 'b', 'c', 'd', 'e'})
    EXPECT_EQ(list >> 1, List{'e', 'a', 'b', 'c', 'd'})
    EXPECT_EQ(list >> 2, List{'d', 'e', 'a', 'b', 'c'})
    EXPECT_EQ(list >> 3, List{'c', 'd', 'e', 'a', 'b'})
    EXPECT_EQ(list >> 4, List{'b', 'c', 'd', 'e', 'a'})
  end,

  [test 'shift left <<'] = function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    EXPECT_EQ(list << 0, List{'a', 'b', 'c', 'd', 'e'})
    EXPECT_EQ(list << 1, List{'b', 'c', 'd', 'e', 'a'})
    EXPECT_EQ(list << 2, List{'c', 'd', 'e', 'a', 'b'})
    EXPECT_EQ(list << 3, List{'d', 'e', 'a', 'b', 'c'})
    EXPECT_EQ(list << 4, List{'e', 'a', 'b', 'c', 'd'})
  end,
}

if main_file() then
  unit.run_unit_tests()
end
