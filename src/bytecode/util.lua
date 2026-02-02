local bytecode = require 'bcode'

local function write_indented(file, indent, ...)
  for i=1, indent do
    file:write('  ')
  end
  file:write(...)
end

local function write_recursive(file, o, indent)
  indent = indent or 0
  local mt = getmetatable(o)
  if mt and mt.__tostring then
    file:write(tostring(o))
  elseif type(o) == 'table' then
    file:write('{\n')
    local keys = {}
    for k in pairs(o) do
      table.insert(keys, k)
    end
    table.sort(keys)
    for i, k in ipairs(keys) do
      local v = o[k]
      write_indented(file, indent + 1, k, ' = ')
      write_recursive(file, v, indent + 1)
      file:write(',\n')
    end
    write_indented(file, indent, '}')
  elseif type(o) == 'string' then
    file:write("'", tostring(o), "'")
  else
    file:write(tostring(o))
  end
end

local function dump_file(filename, chunk)
  -- do
  --   local file <close> = assert(io.open(filename .. '.bin', 'wb'))
  --   file:write(chunk)
  -- end
  local chunk_bytes = bytecode.read_bytes(chunk)
  do
    local file <close> = assert(io.open(filename .. '.txt', 'w'))
    write_recursive(file, chunk_bytes)
  end
  -- write_recursive(io.stdout, chunk_bytes)
end

local function compare_two_functions(f1, f2)
  dump_file('left', string.dump(f1))
  dump_file('right', string.dump(f2))
end

return {
  write_recursive = write_recursive,
  compare_two_functions = compare_two_functions,
  dump_file = dump_file,
}