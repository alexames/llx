local llx = require 'llx'
require 'llx/check_arguments'

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

local NoteSchema = llx.Schema{
  title="NoteSchema",
  type=llx.Table,
  properties={
    pitch={
      type=llx.Integer,
      minimum=150,
    },
    volume={
      type=llx.Integer,
      maximum=50,
    },
    duration={type=llx.Integer},
    time={type=llx.Integer},
  },
  required = {'pitch','volume','duration'},
}

local UnionSchema = llx.Schema{
  __name='UnionSchema',
  type=llx.Union{llx.Number, llx.String},
  type_schemas={
    Number={
      type=llx.Number,
    },
    String={
      type=llx.String,
      min_length=3,
      pattern='%s%s 123',
    },
  },
}

function mytestfunc(a, b, c, d)
  llx.check_arguments{a=llx.Integer, b=llx.Float, c=llx.Number, d=UnionSchema}
  return true
end

-- print(mytestfunc(10, 10.0, 1, '\t\t 123'))