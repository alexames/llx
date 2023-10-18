require 'lx/base'

TestLogger = class 'TestLogger' {
  test_suite_name = function() return self.test_suite.__class_name end;

  prelude = function() end;

  class_preamble = function(test_suite)
    printf('%s[==========]%s Running %s tests from %s%s%s',
            color(green), reset(), #test_suite:tests(), color(bright_cyan), 
            test_suite:name(), reset())
  end;

  test_begin = function(test_suite, test_name)
    printf('%s[ Run      ] %s%s.%s%s',
           color(green), color(bright_cyan), test_suite:name(), test_name, reset())
  end;

  test_end = function(test_suite, test_name, successful)
    if successful then
      printf('%s[       OK ] %s%s.%s%s',
             color(green), color(bright_cyan), test_suite:name(), test_name, reset())
    else
      printf('%s[  FAILURE ] %s%s.%s%s\n%s',
             color(red), color(bright_cyan), test_suite:name(), test_name, reset(), err)
    end
  end;

  class_conclusion = function(test_suite, failure_count)
    if failure_count == 0 then
      printf('%s[==========]%s All %s tests succeeded!',
             color(green), reset(), test_suite:name())
    else
      printf('%s[==========]%s %s / %s failed.',
             color(red), reset(), failure_count, #test_suite:tests())
    end
    print()
  end;

  finale = function(total_failure_count, total_test_count)
    if total_failure_count == 0 then
      printf('%s[==========]%s All tests succeeded!',
             color(green), reset())
    else
      printf('%s[==========]%s %s / %s failed.',
             color(red), reset(), total_failure_count, total_test_count)
      -- for i, v in ipairs(failure_list) do
      --   printf('%s[  FAILED  ] %s%s',
      --          color(red), v, reset())
      -- end
    end
  end;
}