-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local matchers = require 'llx/src/types/matchers'

Boolean = require 'llx/src/types/boolean'
Float = require 'llx/src/types/float'
Function = require 'llx/src/types/function'
Integer = require 'llx/src/types/integer'
Nil = require 'llx/src/types/nil'
Number = require 'llx/src/types/number'
String = require 'llx/src/types/string'
Table = require 'llx/src/types/table'
Thread = require 'llx/src/types/thread'
Userdata = require 'llx/src/types/userdata'

List = require 'llx/src/types/list'
Set = require 'llx/src/types/set'

Any=matchers.Any
Union=matchers.Union
Optional=matchers.Optional
Dict=matchers.Dict
Tuple=matchers.Tuple

return {
  Any=matchers.Any,
  Union=matchers.Union,
  Optional=matchers.Optional,
  Dict=matchers.Dict,
  Tuple=matchers.Tuple,

	Boolean=Boolean,
	Float=Float,
	Function=Function,
	Integer=Integer,
	Nil=Nil,
	Number=Number,
	String=String,
	Table=Table,
	Thread=Thread,
	Userdata=Userdata,

  ['boolean']=Boolean,
  ['function']=Function,
  ['nil']=Nil,
  ['number']=Number,
  ['string']=String,
  ['table']=Table,
  ['thread']=Thread,
  ['userdata']=Userdata,
}
