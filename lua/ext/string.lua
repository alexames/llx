
function string:join(t)
  local result = ''
  for i=1, #t do
    if i > 1 then
      result = result .. self
    end
    result = result .. t[i]
  end
  return result
end

function string:empty()
  return #self == 0
end
