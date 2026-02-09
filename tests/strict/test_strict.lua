local unit = require 'llx.unit'
local llx = require 'llx'
local strict = require 'llx.strict'

_ENV = unit.create_test_env(_ENV)

describe('lock_global_table', function()
  it('should return a table with a close metamethod', function()
    local lock = strict.lock_global_table()
    local mt = getmetatable(lock)
    expect(mt).to_not.be_nil()
    expect(type(mt.__close)).to.be_equal_to('function')
    -- Manually invoke close to unlock
    mt.__close(lock)
  end)

  it('should prevent writing new keys to _G', function()
    local lock = strict.lock_global_table()
    local success, err = pcall(function()
      _G['__test_strict_new_key_xyz'] = 'value'
    end)
    -- Manually unlock
    getmetatable(lock).__close(lock)
    expect(success).to.be_false()
    expect(type(err)).to.be_equal_to('string')
  end)

  it('should include the key name in the error message', function()
    local lock = strict.lock_global_table()
    local success, err = pcall(function()
      _G['__test_strict_key_name_abc'] = 42
    end)
    getmetatable(lock).__close(lock)
    expect(success).to.be_false()
    expect(err).to.contain('__test_strict_key_name_abc')
  end)

  it('should include the value in the error message', function()
    local lock = strict.lock_global_table()
    local success, err = pcall(function()
      _G['__test_strict_value_check'] = 'hello_world'
    end)
    getmetatable(lock).__close(lock)
    expect(success).to.be_false()
    expect(err).to.contain('hello_world')
  end)

  it('should include writes disallowed in the error message', function()
    local lock = strict.lock_global_table()
    local success, err = pcall(function()
      _G['__test_strict_msg_check'] = true
    end)
    getmetatable(lock).__close(lock)
    expect(success).to.be_false()
    expect(err).to.contain('writes disallowed')
  end)

  it('should still allow reading existing globals', function()
    local lock = strict.lock_global_table()
    -- _G.print should still be readable while locked
    local p = _G['print']
    getmetatable(lock).__close(lock)
    expect(p).to.be_equal_to(print)
  end)

  it('should still allow reading the table module', function()
    local lock = strict.lock_global_table()
    local t = _G['table']
    getmetatable(lock).__close(lock)
    expect(t).to.be_equal_to(table)
  end)

  it('should restore write ability after close', function()
    local lock = strict.lock_global_table()
    -- Unlock by invoking the close metamethod manually
    getmetatable(lock).__close(lock)
    -- Now writing should work again
    local success, err = pcall(function()
      _G['__test_strict_restored_write'] = 'restored'
    end)
    -- Clean up
    _G['__test_strict_restored_write'] = nil
    expect(success).to.be_true()
  end)

  it('should work with the <close> attribute in a do-end block', function()
    -- After the do-end block, the lock should be automatically released
    do
      local lock <close> = strict.lock_global_table()
      local success, err = pcall(function()
        _G['__test_strict_close_attr'] = 'locked'
      end)
      expect(success).to.be_false()
    end
    -- Now the lock should be released
    local success, err = pcall(function()
      _G['__test_strict_close_attr'] = 'unlocked'
    end)
    _G['__test_strict_close_attr'] = nil
    expect(success).to.be_true()
  end)

  it('should allow rawset to bypass the lock', function()
    local lock = strict.lock_global_table()
    -- rawset bypasses __newindex
    local success, err = pcall(function()
      rawset(_G, '__test_strict_rawset', 'bypassed')
    end)
    getmetatable(lock).__close(lock)
    -- Clean up
    rawset(_G, '__test_strict_rawset', nil)
    expect(success).to.be_true()
  end)

  it('should handle multiple lock/unlock cycles', function()
    for i = 1, 3 do
      local lock = strict.lock_global_table()
      local success, _ = pcall(function()
        _G['__test_strict_cycle_' .. i] = i
      end)
      expect(success).to.be_false()
      getmetatable(lock).__close(lock)
    end
    -- After all unlocks, writing should work
    local success, _ = pcall(function()
      _G['__test_strict_cycle_final'] = 'ok'
    end)
    _G['__test_strict_cycle_final'] = nil
    expect(success).to.be_true()
  end)

  it('should prevent writing to any key type', function()
    local lock = strict.lock_global_table()
    -- Try writing with a numeric key
    local success_num, _ = pcall(function()
      _G[99999] = 'numeric_key'
    end)
    -- Try writing with a boolean key
    local success_bool, _ = pcall(function()
      _G[true] = 'bool_key'
    end)
    getmetatable(lock).__close(lock)
    expect(success_num).to.be_false()
    expect(success_bool).to.be_false()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end
