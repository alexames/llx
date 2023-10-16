
function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local lua_exe = arg[-1]
local TERMINAL_COLORS = lua_exe ~= 'lua'

black          = {fg=30, bg=40}
red            = {fg=31, bg=41}
green          = {fg=32, bg=42}
yellow         = {fg=33, bg=43}
blue           = {fg=34, bg=44}
magenta        = {fg=35, bg=45}
cyan           = {fg=36, bg=46}
white          = {fg=37, bg=47}
bright_black   = {fg=90, bg=100}
bright_red     = {fg=91, bg=101}
bright_green   = {fg=92, bg=102}
bright_yellow  = {fg=93, bg=103}
bright_blue    = {fg=94, bg=104}
bright_magenta = {fg=95, bg=105}
bright_cyan    = {fg=96, bg=106}
bright_white   = {fg=97, bg=107}


function color(fg, bg)
  if not TERMINAL_COLORS then return '' end
  fg = fg and fg.fg
  bg = bg and bg.bg
  assert(fg or bg)
  if fg and bg then 
    return string.format('\27[%s;%sm', fg, bg)
  else
    return string.format('\27[%sm', fg or bg)
  end
end

function reset()
  if not TERMINAL_COLORS then return '' end
  return '\27[0m'
end