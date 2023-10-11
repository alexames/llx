require 'class'

class 'Note' {
  __init = function(self, arg)
    if pitch < 0 or pitch > 255 then
      error(string.format("Invalid pitch: %s", pitch))
    end
    self.pitch = arg.pitch
    self.time = arg.time
    self.duration = arg.duration
    self.volume = arg.volume or 1.0
  end,

  setStart = function(self, start)
    self.duration = finish() - start
    self.time = start
  end,

  start = function(self)
    return self.time
  end,

  setFinish = function(self, finish)
    self.duration = finish - self.time
  end,

  finish = function(self)
    return self.time + self.duration
  end,

  __repr = function(self)
    return format("Note{pitch=%s, time=%s, duration=%s, volume=%s}", self.pitch, self.time, self.duration, self.volume)
  end,
}


if false then
  require 'unit'
  TestCase 'NoteTest' {
    test_setStart = function(self)
      self.assertTrue(False)
    end,

    test_start = function(self)
      self.assertTrue(False)
    end,

    test_setEnd = function(self)
      self.assertTrue(False)
    end,

    test_end = function(self)
      self.assertTrue(False)
    end,

    test_writeFile = function(self)
      self.assertTrue(False)
    end,

    test_repr = function(self)
      self.assertTrue(False)
    end,
  }
end