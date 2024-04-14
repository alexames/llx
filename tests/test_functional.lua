-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/core'
require 'llx/debug/trace'
require 'llx/operators'
require 'llx/types/list'
require 'llx/types/table'
require 'llx/types/string'

test_class 'RangeTest' {
  [test ''] = function()
    range(a, b, c)
  end
}

test_class 'GeneratorTest' {
  [test ''] = function()
    generator(iterator, state, control, closing)
  end
}

test_class 'MapTest' {
  [test ''] = function()
    map(lambda, ...)
  end
}

test_class 'FilterTest' {
  [test ''] = function()
    filter(lambda, sequence)
  end
}

test_class 'CountTest' {
  [test ''] = function()
    count(start, step)
  end
}

test_class 'CycleTest' {
  [test ''] = function()
    cycle(sequence)
  end
}

test_class 'Repeat_ElemTest' {
  [test ''] = function()
    repeat_elem()
  end
}

test_class 'AccumulateTest' {
  [test ''] = function()
    accumulate(sequence, lambda, initial_value)
  end
}

test_class 'BatchedTest' {
  [test ''] = function()
    batched(iterable, n)
  end
}

test_class 'ChainTest' {
  [test ''] = function()
    chain()
  end
}

test_class 'CompressTest' {
  [test ''] = function()
    compress()
  end
}

test_class 'Drop_WhileTest' {
  [test ''] = function()
    drop_while()
  end
}

test_class 'FilterfalseTest' {
  [test ''] = function()
    filterfalse()
  end
}

test_class 'Group_ByTest' {
  [test ''] = function()
    group_by()
  end
}

test_class 'SliceTest' {
  [test ''] = function()
    slice()
  end
}

test_class 'PairwiseTest' {
  [test ''] = function()
    pairwise()
  end
}

test_class 'Star_MapTest' {
  [test ''] = function()
    star_map()
  end
}

test_class 'Take_WhileTest' {
  [test ''] = function()
    take_while()
  end
}

test_class 'TeeTest' {
  [test ''] = function()
    tee()
  end
}

test_class 'SliceTest' {
  [test ''] = function()
    slice()
  end
}

test_class 'Zip_LongestTest' {
  [test ''] = function()
    zip_longest()
  end
}

test_class 'PermutationsTest' {
  [test ''] = function()
    permutations()
  end
}

test_class 'CombinationsTest' {
  [test ''] = function()
    combinations()
  end
}

test_class 'ReduceTest' {
  [test ''] = function()
    reduce(sequence, lambda, initial_value)
  end
}

test_class 'MinTest' {
  [test ''] = function()
    min(sequence)
  end
}

test_class 'MaxTest' {
  [test ''] = function()
    max(sequence)
  end
}

test_class 'SumTest' {
  [test ''] = function()
    sum(sequence)
  end
}

test_class 'ProductTest' {
  [test ''] = function()
    product(sequence)
  end
}

test_class 'Zip_ImplTest' {
  [test ''] = function()
    zip_impl(iterators, result_handler)
  end
}

test_class 'Zip_PackedTest' {
  [test ''] = function()
    zip_packed(...)
  end
}

test_class 'ZipTest' {
  [test ''] = function()
    zip(...)
  end
}

test_class 'Cartesian_ProductTest' {
  [test ''] = function()
    cartesian_product(...)
  end
}

