from typing import Any
from itertools import chain
from lupa.lua54 import LuaRuntime, LuaError

_L = LuaRuntime(unpack_returned_tuples=True)
_L.eval('function(p) print = p end')(print)

def _prepare_arg(arg):
  if isinstance(arg, LuaValue):
    return arg._v
  elif isinstance(arg, dict) or isinstance(arg, list):
    return _L.table_from(arg, recursive=True)
  else:
    return arg

def _prepare_args(*args, **kwargs):
  if kwargs:
    assert len(args) in (0, 1)
    return tuple(_prepare_arg(arg) for arg in chain(args, [kwargs]))
  else:
    return tuple(_prepare_arg(arg) for arg in args)

def _prepare_result(result):
  if type(result) in (None.__class__, bool, int, float, str):
    return result
  else:
    return LuaValue(result)

def _prepare_results(results):
  if isinstance(results, tuple):
    return tuple(_prepare_result(result) for result in results)
  else:
    return _prepare_result(results)

class LuaValue:
  def __init__(self, v=None, parent=None):
    super().__setattr__('_v', v)
    super().__setattr__('_parent', parent)
    super().__setattr__('_setfield', _L.eval('function(t, k, v) t[k] = v end'))
    super().__setattr__('_getfield', _L.eval('function(t, k) return t[k] end'))

  def __setattr__(self, k, v):
    self._setfield(self._v, k, v)

  def __getattr__(self, k):
    return LuaValue(self._getfield(self._v, k), self)

  def __setitem__(self, k, v):
    self._setfield(self._v, k, v)

  def __getitem__(self, k):
    return LuaValue(self._getfield(self._v, k), self)

  def _eval_operator(self, operator):
    return _L.eval(f'function(a, b) return a {operator} b end')

  def __fadd__(self, other):
    return self._eval_operator('+')(*_prepare_args(self, other))
  def __add__(self, other):
    return self._eval_operator('+')(*_prepare_args(self, other))
  def __sub__(self, other):
    return self._eval_operator('-')(*_prepare_args(self, other))
  def __mul__(self, other):
    return self._eval_operator('*')(*_prepare_args(self, other))
  def __rmul__(self, other):
    return self._eval_operator('*')(*_prepare_args(self, other))
  def __div__(self, other):
    return self._eval_operator('/')(*_prepare_args(self, other))

  def method(self, *args: Any, **kwargs) -> Any:
    '''docstring'''
    return self.function(self._parent, *args, **kwargs)

  def function(self, *args: Any, **kwargs) -> Any:
    '''docstring'''
    try:
      return _prepare_results(self._v(*_prepare_args(*args, **kwargs)))
    except LuaError as e:
      print(f'Error: {e}')
      raise e

  def _is_class_method(self):
    try:
      return _L.eval(
        'function(v) return v and v.__is_llx_class end')(self._parent)
    except LuaError:
      return False

  def __call__(self, *args: Any, **kwargs) -> Any:
    '''docstring'''
    if self._is_class_method():
      return self.method(*args, **kwargs)
    else:
      return self.function(*args, **kwargs)

  def __str__(self):
    return str(self._v)

def require(module):
  return LuaValue(_L.eval(f'require("{module}")')[0])


_ENV = LuaValue(_L.eval('_G'))
