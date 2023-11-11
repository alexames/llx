local basic_types = require 'llx/src/types/basic_types'
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

Any=basic_types.Any
Union=basic_types.Union
Optional=basic_types.Optional
Dict=basic_types.Dict
Tuple=basic_types.Tuple

return {
  Any=basic_types.Any,
  Union=basic_types.Union,
  Optional=basic_types.Optional,
  Dict=basic_types.Dict,
  Tuple=basic_types.Tuple,

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
