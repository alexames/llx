local filename = 'llx'
local file_prefix = '../'

function parse_dependencies(filename, files)
  local files = files or {}
  if files[filename] then return files end

  local current_file_dependency_graph = {}
  files[filename] = current_file_dependency_graph

  local file <close> = io.open(file_prefix .. filename .. '.lua')
                       or io.open(file_prefix .. filename .. '/init.lua')
  if file == nil then
    print('Could not load ' .. filename)
    return files
  end
  for line in file:lines() do
    local comment_index = line:find('--', 1, true)
    if comment_index then
      line = line:sub(1, comment_index - 1)
    end
    local match = line:match [[require%s*%(?['"]([%w_./-]+)['"]%)?]]
    if match then
      table.insert(current_file_dependency_graph, match)
      parse_dependencies(match, files)
    end
  end
  return files
end

function graphviz(graph)
  local result = setmetatable({}, {__index=table})
  result:insert 'digraph G {\n'
  result:insert '  node [style=filled,shape=rectangle];\n'
  for filename, node in pairs(graph) do
    for i, dependency in ipairs(node) do
    result:insert '  "'
    result:insert(filename)
    result:insert '" -> "'
    result:insert(dependency)
    result:insert '"\n'
    end
  end
  result:insert '}'
  return table.concat(result)
end

dependency_graph = parse_dependencies(filename)
print(graphviz(dependency_graph))