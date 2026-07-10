local unit = require 'llx.unit'
local llx = require 'llx'
local pretty = require 'llx.pretty'

_ENV = unit.create_test_env(_ENV)

describe('pretty.format primitives', function()
  it('formats numbers as integers when integral', function()
    expect(pretty.format(42)).to.be_equal_to('42')
    expect(pretty.format(0)).to.be_equal_to('0')
    expect(pretty.format(-1)).to.be_equal_to('-1')
  end)

  it('formats floats with their natural representation', function()
    expect(pretty.format(3.14)).to.be_equal_to('3.14')
  end)

  it('formats special floats as named constants', function()
    expect(pretty.format(0/0)).to.be_equal_to('nan')
    expect(pretty.format(math.huge)).to.be_equal_to('math.huge')
    expect(pretty.format(-math.huge)).to.be_equal_to('-math.huge')
  end)

  it('formats booleans as literals', function()
    expect(pretty.format(true)).to.be_equal_to('true')
    expect(pretty.format(false)).to.be_equal_to('false')
  end)

  it('formats nil as the keyword', function()
    expect(pretty.format(nil)).to.be_equal_to('nil')
  end)

  it('quotes strings safely', function()
    expect(pretty.format('hi')).to.be_equal_to('"hi"')
    expect(pretty.format('with "quotes"')).to.contain('with')
    -- Tab/newline survive the round-trip via %q escaping
    expect(pretty.format('a\nb')).to.contain('a')
  end)
end)

describe('pretty.format tables', function()
  it('formats an empty table as {}', function()
    expect(pretty.format({})).to.be_equal_to('{}')
  end)

  it('formats a sequence inline when it fits', function()
    expect(pretty.format({1, 2, 3})).to.be_equal_to('{1, 2, 3}')
  end)

  it('formats a sparse map inline when it fits', function()
    expect(pretty.format({a = 1, b = 2})).to.be_equal_to('{a = 1, b = 2}')
  end)

  it('renders keys with sequence portion first', function()
    -- Sequence keys 1..n come before non-sequence keys regardless
    -- of pairs() iteration order.
    local out = pretty.format({10, 20, x = 'y'})
    expect(out).to.be_equal_to('{10, 20, x = "y"}')
  end)

  it('quotes reserved words as keys', function()
    local out = pretty.format({['function'] = 1})
    expect(out).to.contain('["function"]')
  end)

  it('quotes non-identifier string keys', function()
    local out = pretty.format({['has space'] = 1})
    expect(out).to.contain('["has space"]')
  end)

  it('sorts non-sequence keys deterministically', function()
    -- Re-running produces the same output for the same input,
    -- not pairs-order dependent.
    local a = pretty.format({c = 3, a = 1, b = 2})
    local b = pretty.format({a = 1, b = 2, c = 3})
    expect(a).to.be_equal_to(b)
  end)
end)

describe('pretty.format multi-line', function()
  it('breaks tables that exceed the width budget', function()
    local long = {}
    for i = 1, 30 do long[i] = i end
    local out = pretty.format(long)
    expect(out:find('\n', 1, true)).to_not.be_nil()
  end)

  it('breaks when a key prefix would push the line over', function()
    -- The bug this caught: a 60-char value with a 30-char key
    -- prefix should break to multi-line, not stay inline.
    local out = pretty.format({
      addresses = {{city='New York', zip='10001'},
                   {city='Los Angeles', zip='90001'}},
    })
    expect(out:find('\n', 1, true)).to_not.be_nil()
  end)

  it('respects a custom width', function()
    -- Width 10 forces almost everything multi-line.
    local out = pretty.format({1, 2, 3}, {width = 5})
    expect(out:find('\n', 1, true)).to_not.be_nil()
  end)

  it('respects a custom indent', function()
    local out = pretty.format({1, 2, 3}, {width = 1, indent = '\t'})
    expect(out:find('\t', 1, true)).to_not.be_nil()
  end)
end)

describe('pretty.format cycle handling', function()
  it('emits <cycle> for self-references', function()
    local t = {}
    t.self = t
    local out = pretty.format(t)
    expect(out).to.contain('<cycle>')
  end)

  it('handles indirect cycles', function()
    local a, b = {}, {}
    a.b = b
    b.a = a
    -- Should not stack-overflow.
    local out = pretty.format(a)
    expect(out).to.contain('<cycle>')
  end)

  it('lets the same table appear multiple times without cycling', function()
    local shared = {x = 1}
    local container = {first = shared, second = shared}
    -- shared isn't a cycle; both views should render fully.
    local out = pretty.format(container)
    expect(out).to_not.contain('<cycle>')
    -- Both refs render the inner content.
    local _, count = out:gsub('x = 1', '')
    expect(count).to.be_equal_to(2)
  end)
end)

describe('pretty.format max_depth', function()
  it('truncates deeper nesting with {...}', function()
    local out = pretty.format(
      {a = {b = {c = {d = 1}}}},
      {max_depth = 2})
    expect(out).to.contain('{...}')
  end)

  it('does not truncate at exactly max_depth - 1', function()
    local out = pretty.format({a = {b = 1}}, {max_depth = 5})
    expect(out).to_not.contain('{...}')
  end)
end)

describe('pretty.format custom __tostring', function()
  it('uses the metatable __tostring for classes', function()
    local list = llx.List{1, 2, 3}
    expect(pretty.format(list)).to.be_equal_to(tostring(list))
  end)

  it('uses __tostring for plain tables with one set', function()
    local t = setmetatable({hidden = 'never_seen'}, {
      __tostring = function() return '<custom>' end,
    })
    expect(pretty.format(t)).to.be_equal_to('<custom>')
  end)
end)

describe('pretty.pprint', function()
  it('writes the same string as format, with a newline', function()
    -- Capture stdout by redirecting io.write.
    local writes = {}
    local original = io.write
    io.write = function(...)
      for _, s in ipairs({...}) do writes[#writes + 1] = s end
    end
    local ok, err = pcall(pretty.pprint, {1, 2, 3})
    io.write = original
    if not ok then error(err) end
    local combined = table.concat(writes)
    expect(combined).to.contain('{1, 2, 3}')
    expect(combined).to_not.be_equal_to('{1, 2, 3}')  -- includes newline
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
