schema = require 'llx/src/schema'
types = require 'llx/src/types'
List = require 'llx/src/collections/list'
require 'llx/src/check_arguments'

-- local s = schema.Schema{
--   type=Table,
--   properties={
--     id = {type=String},
--     name = {type=String},
--     age = {type=types.Union{Number,String}},
--     numbers = {
--       type=List,
--       items={type=Number},
--     },
--     subtable = {
--       type=Table,
--       properties={
--         id = {type=String},
--         name = {type=String},
--         age = {type=types.Union{Number,String}}
--       },
--     },
--   },
--   required = {'id','name','age'},
-- }

local NoteSchema = schema.Schema{
  title="NoteSchema",
  type=Table,
  properties={
    pitch = {type=Integer},
    volume = {type=Integer},
    duration = {type=Integer},
    time = {type=Integer},
  },
  required = {'pitch','volume','duration'},
}

function mytestfunc(a, b, c, d)
  check_arguments{a=Integer, b=Float, c=Number, d=NoteSchema}
  return true
end

print(mytestfunc(10, 10.0, 1, {pitch=100, duration=100}))