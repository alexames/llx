return function(...)
  local source = debug.getinfo(2,'S').source 
  local line = debug.getinfo(2,'l').currentline
  print(string.format('%s:%s', source, line), ...)
end