local unit = require 'llx.unit'
local llx = require 'llx'
local isinstance = require 'llx.isinstance' . isinstance

local Exception = llx.exceptions.Exception
local ExceptionGroup = llx.exceptions.ExceptionGroup
local IndexError = llx.exceptions.IndexError
local InvalidArgumentException = llx.exceptions.InvalidArgumentException
local InvalidArgumentTypeException = llx.exceptions.InvalidArgumentTypeException
local NotImplementedException = llx.exceptions.NotImplementedException
local RuntimeError = llx.exceptions.RuntimeError
local SchemaException = llx.exceptions.SchemaException
local SchemaFieldTypeMismatchException =
  llx.exceptions.SchemaFieldTypeMismatchException
local SchemaConstraintFailureException =
  llx.exceptions.SchemaConstraintFailureException
local SchemaMissingFieldException = llx.exceptions.SchemaMissingFieldException
local TypeError = llx.exceptions.TypeError
local ValueException = llx.exceptions.ValueException

-- Helper: create a fake type table with a __name field, used by
-- InvalidArgumentTypeException and SchemaFieldTypeMismatchException.
local function fake_type(name)
  return { __name = name }
end

_ENV = unit.create_test_env(_ENV)

--------------------------------------------------------------------------------
-- Exception (base class)
--------------------------------------------------------------------------------

describe('Exception', function()
  it('should store the message in the what field', function()
    local e = Exception('something went wrong')
    expect(e.what).to.be_equal_to('something went wrong')
  end)

  it('should capture a traceback that is not nil', function()
    local e = Exception('error')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should capture a traceback that is a string', function()
    local e = Exception('error')
    expect(e.traceback).to.be_a('string')
  end)

  it('should include the class name in tostring output', function()
    local e = Exception('msg')
    local s = tostring(e)
    expect(s).to.contain('Exception')
  end)

  it('should include the message in tostring output', function()
    local e = Exception('specific message')
    local s = tostring(e)
    expect(s).to.contain('specific message')
  end)

  it('should include the traceback in tostring output', function()
    local e = Exception('msg')
    local s = tostring(e)
    expect(s).to.contain('stack traceback')
  end)

  it('should be an instance of Exception', function()
    local e = Exception('test')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should work with an empty message', function()
    local e = Exception('')
    expect(e.what).to.be_equal_to('')
  end)

  it('should work with a multi-line message', function()
    local e = Exception('line1\nline2')
    expect(e.what).to.be_equal_to('line1\nline2')
  end)
end)

--------------------------------------------------------------------------------
-- ExceptionGroup
--------------------------------------------------------------------------------

describe('ExceptionGroup', function()
  it('should store the exception_list field', function()
    local e1 = Exception('error one')
    local e2 = Exception('error two')
    local eg = ExceptionGroup({e1, e2})
    expect(eg.exception_list).to_not.be_nil()
  end)

  it('should have the correct number of exceptions '
    .. 'in exception_list', function()
    local e1 = Exception('error one')
    local e2 = Exception('error two')
    local eg = ExceptionGroup({e1, e2})
    expect(#eg.exception_list).to.be_equal_to(2)
  end)

  it('should combine what messages from all exceptions', function()
    local e1 = Exception('first')
    local e2 = Exception('second')
    local eg = ExceptionGroup({e1, e2})
    expect(eg.what).to.contain('first')
  end)

  it('should include the second exception message in what', function()
    local e1 = Exception('first')
    local e2 = Exception('second')
    local eg = ExceptionGroup({e1, e2})
    expect(eg.what).to.contain('second')
  end)

  it('should capture a traceback', function()
    local e1 = Exception('a')
    local eg = ExceptionGroup({e1})
    expect(eg.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e1 = Exception('a')
    local eg = ExceptionGroup({e1})
    local s = tostring(eg)
    expect(s).to.contain('ExceptionGroup')
  end)

  it('should be an instance of Exception', function()
    local eg = ExceptionGroup({Exception('a')})
    expect(isinstance(eg, Exception)).to.be_true()
  end)

  it('should be an instance of ExceptionGroup', function()
    local eg = ExceptionGroup({Exception('a')})
    expect(isinstance(eg, ExceptionGroup)).to.be_true()
  end)

  it('should handle a single exception in the list', function()
    local e1 = Exception('only one')
    local eg = ExceptionGroup({e1})
    expect(eg.what).to.contain('only one')
    expect(#eg.exception_list).to.be_equal_to(1)
  end)

  it('should handle three exceptions in the list', function()
    local e1 = Exception('a')
    local e2 = Exception('b')
    local e3 = Exception('c')
    local eg = ExceptionGroup({e1, e2, e3})
    expect(#eg.exception_list).to.be_equal_to(3)
    expect(eg.what).to.contain('a')
    expect(eg.what).to.contain('b')
    expect(eg.what).to.contain('c')
  end)
end)

--------------------------------------------------------------------------------
-- IndexError
--------------------------------------------------------------------------------

describe('IndexError', function()
  it('should store the message in the what field', function()
    local e = IndexError('index out of range')
    expect(e.what).to.be_equal_to('index out of range')
  end)

  it('should capture a traceback', function()
    local e = IndexError('index out of range')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = IndexError('bad index')
    local s = tostring(e)
    expect(s).to.contain('IndexError')
  end)

  it('should include the message in tostring output', function()
    local e = IndexError('bad index')
    local s = tostring(e)
    expect(s).to.contain('bad index')
  end)

  it('should be an instance of IndexError', function()
    local e = IndexError('x')
    expect(isinstance(e, IndexError)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = IndexError('x')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should not be an instance of RuntimeError', function()
    local e = IndexError('x')
    expect(isinstance(e, RuntimeError)).to.be_false()
  end)
end)

--------------------------------------------------------------------------------
-- InvalidArgumentException
--------------------------------------------------------------------------------

describe('InvalidArgumentException', function()
  it('should format what with argument index and reason', function()
    local e = InvalidArgumentException(1, 'must be positive')
    expect(e.what).to.contain('bad argument #1')
  end)

  it('should include the failure reason in what', function()
    local e = InvalidArgumentException(1, 'must be positive')
    expect(e.what).to.contain('must be positive')
  end)

  it('should handle a string argument index', function()
    local e = InvalidArgumentException('self', 'cannot be nil')
    expect(e.what).to.contain('bad argument #self')
  end)

  it('should capture a traceback', function()
    local e = InvalidArgumentException(2, 'reason')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = InvalidArgumentException(1, 'reason')
    local s = tostring(e)
    expect(s).to.contain('InvalidArgumentException')
  end)

  it('should be an instance of InvalidArgumentException', function()
    local e = InvalidArgumentException(1, 'reason')
    expect(isinstance(e, InvalidArgumentException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = InvalidArgumentException(1, 'reason')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should format what as bad argument #N followed by reason', function()
    local e = InvalidArgumentException(3, 'expected table')
    expect(e.what).to.be_equal_to('bad argument #3:\n  expected table')
  end)
end)

--------------------------------------------------------------------------------
-- InvalidArgumentTypeException
--------------------------------------------------------------------------------

describe('InvalidArgumentTypeException', function()
  it('should format what with expected and actual type names', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(e.what).to.contain('Number expected, got String')
  end)

  it('should include the argument index in what', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(2, expected, actual)
    expect(e.what).to.contain('bad argument #2')
  end)

  it('should capture a traceback', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    local s = tostring(e)
    expect(s).to.contain('InvalidArgumentTypeException')
  end)

  it('should be an instance of InvalidArgumentTypeException', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(isinstance(e, InvalidArgumentTypeException)).to.be_true()
  end)

  it('should be an instance of InvalidArgumentException', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(isinstance(e, InvalidArgumentException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local expected = fake_type('Number')
    local actual = fake_type('String')
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should use tostring for actual_type when __name is absent', function()
    local expected = fake_type('Number')
    local actual = setmetatable({}, {
      __tostring = function() return 'CustomActual' end
    })
    local e = InvalidArgumentTypeException(1, expected, actual)
    expect(e.what).to.contain('CustomActual')
  end)
end)

--------------------------------------------------------------------------------
-- NotImplementedException
--------------------------------------------------------------------------------

describe('NotImplementedException', function()
  it('should store the message in the what field', function()
    local e = NotImplementedException('not yet done')
    expect(e.what).to.be_equal_to('not yet done')
  end)

  it('should capture a traceback', function()
    local e = NotImplementedException('not yet done')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = NotImplementedException('todo')
    local s = tostring(e)
    expect(s).to.contain('NotImplementedException')
  end)

  it('should include the message in tostring output', function()
    local e = NotImplementedException('feature X')
    local s = tostring(e)
    expect(s).to.contain('feature X')
  end)

  it('should be an instance of NotImplementedException', function()
    local e = NotImplementedException('x')
    expect(isinstance(e, NotImplementedException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = NotImplementedException('x')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should not be an instance of RuntimeError', function()
    local e = NotImplementedException('x')
    expect(isinstance(e, RuntimeError)).to.be_false()
  end)
end)

--------------------------------------------------------------------------------
-- RuntimeError
--------------------------------------------------------------------------------

describe('RuntimeError', function()
  it('should store the message in the what field', function()
    local e = RuntimeError('runtime failure')
    expect(e.what).to.be_equal_to('runtime failure')
  end)

  it('should capture a traceback', function()
    local e = RuntimeError('runtime failure')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = RuntimeError('oops')
    local s = tostring(e)
    expect(s).to.contain('RuntimeError')
  end)

  it('should include the message in tostring output', function()
    local e = RuntimeError('oops')
    local s = tostring(e)
    expect(s).to.contain('oops')
  end)

  it('should be an instance of RuntimeError', function()
    local e = RuntimeError('x')
    expect(isinstance(e, RuntimeError)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = RuntimeError('x')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should not be an instance of IndexError', function()
    local e = RuntimeError('x')
    expect(isinstance(e, IndexError)).to.be_false()
  end)
end)

--------------------------------------------------------------------------------
-- SchemaException
--------------------------------------------------------------------------------

describe('SchemaException', function()
  it('should format what with a dotted path', function()
    local e = SchemaException({'root', 'child'}, 'invalid value')
    expect(e.what).to.contain('`root.child`')
  end)

  it('should include the failure reason in what', function()
    local e = SchemaException({'root', 'child'}, 'invalid value')
    expect(e.what).to.contain('invalid value')
  end)

  it('should use root when path is empty', function()
    local e = SchemaException({}, 'missing field')
    expect(e.what).to.contain('root')
  end)

  it('should store the path field', function()
    local path = {'a', 'b', 'c'}
    local e = SchemaException(path, 'reason')
    expect(e.path).to.be_equal_to(path)
  end)

  it('should capture a traceback', function()
    local e = SchemaException({'x'}, 'reason')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = SchemaException({'x'}, 'reason')
    local s = tostring(e)
    expect(s).to.contain('SchemaException')
  end)

  it('should be an instance of SchemaException', function()
    local e = SchemaException({'x'}, 'reason')
    expect(isinstance(e, SchemaException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = SchemaException({'x'}, 'reason')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should format a single-element path correctly', function()
    local e = SchemaException({'field'}, 'bad')
    expect(e.what).to.contain('`field`')
  end)

  it('should format a deeply nested path correctly', function()
    local e = SchemaException({'a', 'b', 'c', 'd'}, 'deep error')
    expect(e.what).to.contain('`a.b.c.d`')
  end)

  it('should produce the expected what format for a path', function()
    local e = SchemaException({'foo', 'bar'}, 'type mismatch')
    expect(e.what).to.be_equal_to('error at `foo.bar`: type mismatch')
  end)

  it('should produce the expected what format for empty path', function()
    local e = SchemaException({}, 'something wrong')
    expect(e.what).to.be_equal_to('error at root: something wrong')
  end)
end)

--------------------------------------------------------------------------------
-- SchemaFieldTypeMismatchException
--------------------------------------------------------------------------------

describe('SchemaFieldTypeMismatchException', function()
  it('should include expected and actual type names in what', function()
    local e = SchemaFieldTypeMismatchException(
        {'config', 'port'}, fake_type('Number'), fake_type('String'))
    expect(e.what).to.contain('Number expected, got String')
  end)

  it('should include the path in what', function()
    local e = SchemaFieldTypeMismatchException(
        {'config', 'port'}, fake_type('Number'), fake_type('String'))
    expect(e.what).to.contain('`config.port`')
  end)

  it('should store the path field', function()
    local path = {'config', 'port'}
    local e = SchemaFieldTypeMismatchException(
        path, fake_type('Number'), fake_type('String'))
    expect(e.path).to.be_equal_to(path)
  end)

  it('should capture a traceback', function()
    local e = SchemaFieldTypeMismatchException(
        {'x'}, fake_type('A'), fake_type('B'))
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = SchemaFieldTypeMismatchException(
        {'x'}, fake_type('A'), fake_type('B'))
    local s = tostring(e)
    expect(s).to.contain('SchemaFieldTypeMismatchException')
  end)

  it('should be an instance of SchemaFieldTypeMismatchException', function()
    local e = SchemaFieldTypeMismatchException(
        {'x'}, fake_type('A'), fake_type('B'))
    expect(isinstance(e, SchemaFieldTypeMismatchException)).to.be_true()
  end)

  it('should be an instance of SchemaException', function()
    local e = SchemaFieldTypeMismatchException(
        {'x'}, fake_type('A'), fake_type('B'))
    expect(isinstance(e, SchemaException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = SchemaFieldTypeMismatchException(
        {'x'}, fake_type('A'), fake_type('B'))
    expect(isinstance(e, Exception)).to.be_true()
  end)
end)

--------------------------------------------------------------------------------
-- SchemaConstraintFailureException
--------------------------------------------------------------------------------

describe('SchemaConstraintFailureException', function()
  it('should include the path in what', function()
    local e = SchemaConstraintFailureException({'data', 'age'}, 'must be >= 0')
    expect(e.what).to.contain('`data.age`')
  end)

  it('should include the failure reason in what', function()
    local e = SchemaConstraintFailureException({'data', 'age'}, 'must be >= 0')
    expect(e.what).to.contain('must be >= 0')
  end)

  it('should store the path field', function()
    local path = {'data', 'age'}
    local e = SchemaConstraintFailureException(path, 'reason')
    expect(e.path).to.be_equal_to(path)
  end)

  it('should capture a traceback', function()
    local e = SchemaConstraintFailureException({'x'}, 'reason')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = SchemaConstraintFailureException({'x'}, 'reason')
    local s = tostring(e)
    expect(s).to.contain('SchemaConstraintFailureException')
  end)

  it('should be an instance of SchemaConstraintFailureException', function()
    local e = SchemaConstraintFailureException({'x'}, 'reason')
    expect(isinstance(e, SchemaConstraintFailureException)).to.be_true()
  end)

  it('should be an instance of SchemaException', function()
    local e = SchemaConstraintFailureException({'x'}, 'reason')
    expect(isinstance(e, SchemaException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = SchemaConstraintFailureException({'x'}, 'reason')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should use root when path is empty', function()
    local e = SchemaConstraintFailureException({}, 'constraint failed')
    expect(e.what).to.contain('root')
  end)
end)

--------------------------------------------------------------------------------
-- SchemaMissingFieldException
--------------------------------------------------------------------------------

describe('SchemaMissingFieldException', function()
  it('should include the missing field key in what', function()
    local e = SchemaMissingFieldException({'config'}, 'name')
    expect(e.what).to.contain('missing required field name')
  end)

  it('should include the path in what', function()
    local e = SchemaMissingFieldException({'config'}, 'name')
    expect(e.what).to.contain('`config`')
  end)

  it('should store the path field', function()
    local path = {'config'}
    local e = SchemaMissingFieldException(path, 'name')
    expect(e.path).to.be_equal_to(path)
  end)

  it('should capture a traceback', function()
    local e = SchemaMissingFieldException({'x'}, 'y')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = SchemaMissingFieldException({'x'}, 'y')
    local s = tostring(e)
    expect(s).to.contain('SchemaMissingFieldException')
  end)

  it('should be an instance of SchemaMissingFieldException', function()
    local e = SchemaMissingFieldException({'x'}, 'y')
    expect(isinstance(e, SchemaMissingFieldException)).to.be_true()
  end)

  it('should be an instance of SchemaException', function()
    local e = SchemaMissingFieldException({'x'}, 'y')
    expect(isinstance(e, SchemaException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = SchemaMissingFieldException({'x'}, 'y')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should use root when path is empty', function()
    local e = SchemaMissingFieldException({}, 'id')
    expect(e.what).to.contain('root')
    expect(e.what).to.contain('missing required field id')
  end)
end)

--------------------------------------------------------------------------------
-- TypeError
--------------------------------------------------------------------------------

describe('TypeError', function()
  it('should store the message in the what field', function()
    local e = TypeError('wrong type')
    expect(e.what).to.be_equal_to('wrong type')
  end)

  it('should capture a traceback', function()
    local e = TypeError('wrong type')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the class name in tostring output', function()
    local e = TypeError('bad')
    local s = tostring(e)
    expect(s).to.contain('TypeError')
  end)

  it('should include the message in tostring output', function()
    local e = TypeError('bad')
    local s = tostring(e)
    expect(s).to.contain('bad')
  end)

  it('should be an instance of TypeError', function()
    local e = TypeError('x')
    expect(isinstance(e, TypeError)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = TypeError('x')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should not be an instance of RuntimeError', function()
    local e = TypeError('x')
    expect(isinstance(e, RuntimeError)).to.be_false()
  end)
end)

--------------------------------------------------------------------------------
-- ValueException
--------------------------------------------------------------------------------

describe('ValueException', function()
  it('should store the message in the what field', function()
    local e = ValueException('invalid value')
    expect(e.what).to.be_equal_to('invalid value')
  end)

  it('should capture a traceback', function()
    local e = ValueException('invalid value')
    expect(e.traceback).to_not.be_nil()
  end)

  it('should include the message in tostring output', function()
    local e = ValueException('bad val')
    local s = tostring(e)
    expect(s).to.contain('bad val')
  end)

  it('should be an instance of ValueException', function()
    local e = ValueException('x')
    expect(isinstance(e, ValueException)).to.be_true()
  end)

  it('should be an instance of Exception', function()
    local e = ValueException('x')
    expect(isinstance(e, Exception)).to.be_true()
  end)

  it('should not be an instance of TypeError', function()
    local e = ValueException('x')
    expect(isinstance(e, TypeError)).to.be_false()
  end)
end)

--------------------------------------------------------------------------------
-- Cross-type isolation tests
--------------------------------------------------------------------------------

describe('exception type isolation', function()
  it('should not consider IndexError an instance of TypeError', function()
    local e = IndexError('x')
    expect(isinstance(e, TypeError)).to.be_false()
  end)

  it('should not consider TypeError an instance of IndexError', function()
    local e = TypeError('x')
    expect(isinstance(e, IndexError)).to.be_false()
  end)

  it('should not consider RuntimeError an instance of '
    .. 'NotImplementedException', function()
    local e = RuntimeError('x')
    expect(isinstance(e, NotImplementedException)).to.be_false()
  end)

  it('should not consider SchemaException an instance of '
    .. 'InvalidArgumentException', function()
    local e = SchemaException({'p'}, 'r')
    expect(isinstance(e, InvalidArgumentException)).to.be_false()
  end)

  it('should not consider InvalidArgumentException '
    .. 'an instance of SchemaException', function()
    local e = InvalidArgumentException(1, 'reason')
    expect(isinstance(e, SchemaException)).to.be_false()
  end)

  it('should consider all exception types as instances of Exception', function()
    local exceptions = {
      Exception('a'),
      ExceptionGroup({Exception('a')}),
      IndexError('a'),
      InvalidArgumentException(1, 'a'),
      InvalidArgumentTypeException(1, fake_type('A'), fake_type('B')),
      NotImplementedException('a'),
      RuntimeError('a'),
      SchemaException({'p'}, 'a'),
      SchemaFieldTypeMismatchException({'p'}, fake_type('A'), fake_type('B')),
      SchemaConstraintFailureException({'p'}, 'a'),
      SchemaMissingFieldException({'p'}, 'k'),
      TypeError('a'),
      ValueException('a'),
    }
    for _, e in ipairs(exceptions) do
      expect(isinstance(e, Exception)).to.be_true()
    end
  end)
end)

--------------------------------------------------------------------------------
-- Error throwing and catching tests
--------------------------------------------------------------------------------

describe('exception throwing', function()
  it('should be catchable with pcall when thrown via error()', function()
    local ok, err = pcall(function()
      error(RuntimeError('boom'))
    end)
    expect(ok).to.be_false()
    expect(isinstance(err, RuntimeError)).to.be_true()
  end)

  it('should preserve the what field after being thrown', function()
    local ok, err = pcall(function()
      error(IndexError('out of bounds'))
    end)
    expect(err.what).to.be_equal_to('out of bounds')
  end)

  it('should preserve the traceback field after being thrown', function()
    local ok, err = pcall(function()
      error(TypeError('wrong type'))
    end)
    expect(err.traceback).to_not.be_nil()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
