function trace(...)
  local info = debug.getinfo(2, "Sln")
  io.write(string.format('%s:%s', info.source:sub(2), info.currentline))
  if info.name then
    io.write(string.format(':%s', info.name))
  end
  if #{...} > 0 then
    io.write(' ')
  end
  print(...)
end

return {
  trace=trace,
}
