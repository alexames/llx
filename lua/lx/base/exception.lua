require 'lx/base/class'

Exception = class 'Exception' {
  __init = function(self, what)
    self.what = what
  end;

  __tostring = function(self)
    return self.what
  end;
}
