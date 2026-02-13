local unit = require 'llx.unit'
local llx = require 'llx'

local List = llx.List

_ENV = unit.create_test_env(_ENV)

describe('ListTest', function()
  it('should return same table when List is called with table', function()
    local list_table = {}
    local list = List(list_table)
    expect(list_table).to.be_equal_to(list)
  end)

  it('should extend first list with second list', function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    list_a:extend(list_b)
    expect(list_a).to.be_equal_to({1, 2, 3, 4, 5, 6})
  end)

  it('should preserve second list when extending', function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    list_a:extend(list_b)
    expect(list_b).to.be_equal_to({4, 5, 6})
  end)

  it('should iterate over list elements correctly', function()
    local mock = Mock()
    local list = List{'a', 'b', 'c'}
    for i, v in list do
      mock(v)
    end
    expect(mock).to.have_been_called_times(3)
    local calls = mock:mock_get_calls()
    expect(calls[1].args[1]).to.be_equal_to('a')
    expect(calls[2].args[1]).to.be_equal_to('b')
    expect(calls[3].args[1]).to.be_equal_to('c')
  end)

  it('should return true when list contains first element', function()
    local list = List{1, 2, 3}
    expect(list:contains(1)).to.be_truthy()
  end)

  it('should return true when list contains second element', function()
    local list = List{1, 2, 3}
    expect(list:contains(2)).to.be_truthy()
  end)

  it('should return true when list contains third element', function()
    local list = List{1, 2, 3}
    expect(list:contains(3)).to.be_truthy()
  end)

  it('should return false when list does not contain element', function()
    local list = List{1, 2, 3}
    expect(list:contains(4)).to.be_falsy()
  end)

  it('should return sublist from indices 1 to 3', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(1, 3)).to.be_equal_to({1, 2, 3})
  end)

  it('should return sublist with step 2 from indices 1 to 6', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(1, 6, 2)).to.be_equal_to({1, 3, 5})
  end)

  it('should return sublist from indices 2 to 4', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(2, 4)).to.be_equal_to({2, 3, 4})
  end)

  it('should return sublist with step 2 from indices 2 to 6', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(2, 6, 2)).to.be_equal_to({2, 4, 6})
  end)

  it('should return reversed sublist from indices 6 to 1', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(6, 1, -1)).to.be_equal_to({6, 5, 4, 3, 2, 1})
  end)

  it('should return reversed sublist with step -2 '
    .. 'from indices 6 to 1', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(6, 1, -2)).to.be_equal_to({6, 4, 2})
  end)

  it('should return empty list when sub range is invalid', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(1, 0)).to.be_equal_to({})
  end)

  it('should return full list when sub is called with '
    .. 'only start index', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list:sub(0)).to.be_equal_to({1, 2, 3, 4, 5, 6})
  end)

  it('should preserve original list when reverse is called', function()
    local list = List{1, 2, 3, 4, 5, 6}
    local reversed_list = list:reverse()
    expect(list).to.be_equal_to({1, 2, 3, 4, 5, 6})
  end)

  it('should return reversed list when reverse is called', function()
    local list = List{1, 2, 3, 4, 5, 6}
    local reversed_list = list:reverse()
    expect(reversed_list).to.be_equal_to({6, 5, 4, 3, 2, 1})
  end)

  it('should return first element for index 1', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[1]).to.be_equal_to(1)
  end)

  it('should return second element for index 2', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[2]).to.be_equal_to(2)
  end)

  it('should return third element for index 3', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[3]).to.be_equal_to(3)
  end)

  it('should return last element for index -1', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[-1]).to.be_equal_to(6)
  end)

  it('should return second to last element for index -2', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[-2]).to.be_equal_to(5)
  end)

  it('should return third to last element for index -3', function()
    local list = List{1, 2, 3, 4, 5, 6}
    expect(list[-3]).to.be_equal_to(4)
  end)

  it('should return list of elements for list index', function()
    local list = List{'a', 'b', 'c', 'd', 'e', 'f'}
    expect(list[{1, 3, 5}]).to.be_equal_to(List{'a', 'c', 'e'})
  end)

  it('should return list of elements for reversed list index', function()
    local list = List{'a', 'b', 'c', 'd', 'e', 'f'}
    expect(list[{5, 4, 6}]).to.be_equal_to(List{'e', 'd', 'f'})
  end)

  it('should return list of elements for negative list index', function()
    local list = List{'a', 'b', 'c', 'd', 'e', 'f'}
    expect(list[{-3, -2, -1}]).to.be_equal_to(List{'d', 'e', 'f'})
  end)

  it('should return nested list of elements for nested list index', function()
    local list = List{'a', 'b', 'c', 'd', 'e', 'f'}
    expect(list[{{1, 2, 3}, {2, 3, 4}, {3, 4, 5}}]).to.be_equal_to(
      List{List{'a', 'b', 'c'},
           List{'b', 'c', 'd'},
           List{'c', 'd', 'e'}})
  end)

  it('should preserve first list when concatenating', function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    local concat_list = list_a .. list_b
    expect(list_a).to.be_equal_to({1, 2, 3})
  end)

  it('should preserve second list when concatenating', function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    local concat_list = list_a .. list_b
    expect(list_b).to.be_equal_to({4, 5, 6})
  end)

  it('should return concatenated list when using concat operator', function()
    local list_a = List{1, 2, 3}
    local list_b = List{4, 5, 6}
    local concat_list = list_a .. list_b
    expect(concat_list).to.be_equal_to({1, 2, 3, 4, 5, 6})
  end)

  it('should preserve original list when multiplying', function()
    local list = List{1, 2, 3}
    local multiplied_list = list * 3
    expect(list).to.be_equal_to({1, 2, 3})
  end)

  it('should return multiplied list when using mul operator', function()
    local list = List{1, 2, 3}
    local multiplied_list = list * 3
    expect(multiplied_list).to.be_equal_to({1, 2, 3, 1, 2, 3, 1, 2, 3})
  end)

  it('should return same list when shifting right by 0', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 0).to.be_equal_to(List{'a', 'b', 'c', 'd', 'e'})
  end)

  it('should return shifted list when shifting right by 1', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 1).to.be_equal_to(List{'e', 'a', 'b', 'c', 'd'})
  end)

  it('should return shifted list when shifting right by 2', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 2).to.be_equal_to(List{'d', 'e', 'a', 'b', 'c'})
  end)

  it('should return shifted list when shifting right by 3', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 3).to.be_equal_to(List{'c', 'd', 'e', 'a', 'b'})
  end)

  it('should return shifted list when shifting right by 4', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list >> 4).to.be_equal_to(List{'b', 'c', 'd', 'e', 'a'})
  end)

  it('should return same list when shifting left by 0', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 0).to.be_equal_to(List{'a', 'b', 'c', 'd', 'e'})
  end)

  it('should return shifted list when shifting left by 1', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 1).to.be_equal_to(List{'b', 'c', 'd', 'e', 'a'})
  end)

  it('should return shifted list when shifting left by 2', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 2).to.be_equal_to(List{'c', 'd', 'e', 'a', 'b'})
  end)

  it('should return shifted list when shifting left by 3', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 3).to.be_equal_to(List{'d', 'e', 'a', 'b', 'c'})
  end)

  it('should return shifted list when shifting left by 4', function()
    local list = List{'a', 'b', 'c', 'd', 'e'}
    expect(list << 4).to.be_equal_to(List{'e', 'a', 'b', 'c', 'd'})
  end)

  describe('__lt and __le (lexicographic ordering)', function()
    it('should order by first differing element', function()
      expect(List{1, 2, 3} < List{1, 2, 4}).to.be_truthy()
      expect(List{1, 2, 4} < List{1, 2, 3}).to.be_falsy()
    end)

    it('should order shorter list before longer '
      .. 'when prefix matches', function()
      expect(List{1, 2} < List{1, 2, 3}).to.be_truthy()
      expect(List{1, 2, 3} < List{1, 2}).to.be_falsy()
    end)

    it('should not be less than an equal list', function()
      expect(List{1, 2, 3} < List{1, 2, 3}).to.be_falsy()
    end)

    it('should handle empty lists', function()
      expect(List{} < List{1}).to.be_truthy()
      expect(List{1} < List{}).to.be_falsy()
      expect(List{} < List{}).to.be_falsy()
    end)

    it('should support <= for equal lists', function()
      expect(List{1, 2} <= List{1, 2}).to.be_truthy()
    end)

    it('should support <= for less-than lists', function()
      expect(List{1, 2} <= List{1, 3}).to.be_truthy()
    end)

    it('should support <= returning false '
      .. 'for greater lists', function()
      expect(List{1, 3} <= List{1, 2}).to.be_falsy()
    end)

    it('should allow sorting a list of lists', function()
      local lists = {
        List{3, 1}, List{1, 3},
        List{1, 2}, List{2, 1}
      }
      table.sort(lists)
      expect(lists[1]).to.be_equal_to(List{1, 2})
      expect(lists[2]).to.be_equal_to(List{1, 3})
      expect(lists[3]).to.be_equal_to(List{2, 1})
      expect(lists[4]).to.be_equal_to(List{3, 1})
    end)

    it('should work with string elements', function()
      expect(List{'a', 'b'} < List{'a', 'c'}).to.be_truthy()
      expect(List{'b', 'a'} < List{'a', 'b'}).to.be_falsy()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
