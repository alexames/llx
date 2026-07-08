---@meta
-- llx public API surface for the sumneko/luals language server.
-- This file is not loaded at runtime; it exists only to give your
-- editor type-aware completion and hover docs for
-- `local llx = require 'llx'`.
--
-- Class definitions live in stubs/llx/*.lua — luals merges them
-- across the workspace.library entries.

---@class llx
---@field class fun(name: string|table): llx.ClassDefiner
---@field isinstance fun(value: any, type_checker: any): boolean
---@field is_subtype fun(a: any, b: any): boolean
---@field signature_compatible fun(sub: table, super: table): boolean
---@field Schema fun(schema: table): llx.Schema
---@field matches_schema fun(schema: llx.Schema, value: any, nothrow?: boolean): boolean, llx.Exception?
---@field enum fun(name: string): fun(t: table): table
---@field repr fun(value: any): string
---@field tointeger fun(value: any): integer?
---@field tostringf fun(formatter: any, ...: any): string
---@field strict any
---@field string_view fun(s: string, start?: integer, len?: integer): llx.StringView
---@field check_arguments fun(...): nil
---@field getclass fun(value: any): table?
---@field main_file fun(): boolean
-- Type checkers (flattened from llx.types)
---@field Boolean any
---@field Float any
---@field Integer any
---@field Nil any
---@field Number any
---@field String any
---@field Table any
---@field Thread any
---@field Userdata any
---@field Function any
---@field Any any
---@field Union fun(types: table): any
---@field Optional fun(t: any): any
---@field Dict fun(key_type: any, value_type: any): any
---@field Protocol fun(fields: table<string, any>): any
-- Value-type classes (flattened from llx.types, llx.string_view,
-- llx.seq, llx.tuple, llx.hash_table)
---@field List llx.List
---@field Set llx.Set
---@field Seq llx.Seq
---@field StringView llx.StringView
---@field Tuple llx.Tuple
---@field HashTable llx.HashTable
-- Collections (flattened from llx.collections)
---@field Counter llx.Counter
---@field DefaultDict llx.DefaultDict
---@field Deque llx.Deque
---@field Heap llx.Heap
---@field OrderedDict llx.OrderedDict
-- Top-level factories and sum types
---@field namedtuple fun(name: string, fields: string[]): llx.NamedTuple
---@field dataclass fun(name: string, fields: llx.dataclass.field[], opts?: llx.dataclass.opts): llx.DataclassClass
---@field Result llx.Result
---@field Option llx.Option
---@field Ok fun(value: any): llx.Result
---@field Err fun(err: any): llx.Result
---@field Some fun(value: any): llx.Option
---@field None llx.Option
-- Named submodules
---@field bisect llx.bisect
---@field contextlib llx.contextlib
---@field coroutine any
---@field debug any
---@field decorator any
---@field environment any
---@field exceptions llx.exceptions
---@field export any
---@field flow_control any
---@field functional llx.functional
---@field hash any
---@field mathx llx.mathx
---@field method any
---@field operators any
---@field path llx.path
---@field pretty llx.pretty
---@field property any
---@field proxy any
---@field truthy any
---@field type_check_decorator any
---@field bytecode any
local llx = {}

-- Class-system helper types declared here because they don't have
-- a dedicated submodule stub.

---@class llx.ClassDefiner
---@field extends fun(self: llx.ClassDefiner, ...: table): llx.ClassDefiner
---@overload fun(definition: table): table

---@class llx.Schema
---@field __name string
---@field type any

-- Base "namedtuple class" type. Concrete classes returned by
-- namedtuple() inherit this shape; users typically declare their
-- own subclass to capture the specific fields.
--
-- Pattern:
--     ---@class Point : llx.NamedTuple
--     ---@field x number
--     ---@field y number
--     local Point = llx.namedtuple('Point', {'x', 'y'})
---@class llx.NamedTuple
---@operator len: integer
local NamedTuple = {}

---@return string[]
function NamedTuple:fields() end

---@return table<string, any>
function NamedTuple:as_table() end

return llx
