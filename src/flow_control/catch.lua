-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

function catch(exception, handler)
  return {exception=exception, handler=handler}
end

return catch