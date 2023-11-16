-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

function p(...)
  print(...)
  return ...
end

function printtable(t)
  for k, v in pairs(t) do print(k, v) end
end

function printlist(t)
  for i, v in ipairs(t) do print(i, v) end
end
