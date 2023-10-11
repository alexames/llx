require 'lx'

local Exception = class 'Exception' {
  __init = function(self, what)
    self.what = what
  end;

  __tostring = function(self)
    return self.what
  end;
}

local FileNotFoundException = class 'FileNotFoundException' : extends(Exception) {
  __init = function(self)
    self.Exception.__init(self, 'File Not Found')
  end;

  __tostring = Exception.__tostring
}

local function try(t)
  local successful, exception = pcall(t[1])
  if not successful then
    local catch = t[exception.__name]
                  or t.__default
                  or function() error(exception) end
    catch(exception)
  end
end

-- print('ready to try')
-- try {
--   function()
--     error(FileNotFoundException())
--   end,
--   FileNotFoundException=function(e)
--     print('!!!', e)
--   end,
--   __default=function(e)
--     print('???', e)
--   end
-- }
-- print('end')