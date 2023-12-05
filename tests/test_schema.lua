schema = require 'llx/src/schema'
types = require 'llx/src/types'
List = require 'llx/src/types/list'
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
    pitch = {
      type=Integer,
      minimum=150,
    },
    volume = {
      type=Integer,
      maximum=50,
    },
    duration = {type=Integer},
    time = {type=Integer},
  },
  required = {'pitch','volume','duration'},
}

local UnionSchema = schema.Schema{
  __name='UnionSchema',
  type=Union{Number,String},
  type_schemas={
    Number={
      type=Number,
    },
    String={
      type=String,
      min_length=3,
      pattern='%s%s 123',
    },
  },
}

function mytestfunc(a, b, c, d)
  check_arguments{a=Integer, b=Float, c=Number, d=UnionSchema}
  return true
end

-- print(mytestfunc(10, 10.0, 1, '\t\t 123'))