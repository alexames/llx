local unit = require 'llx.unit'
local llx = require 'llx'
local path = require 'llx.path'
local Path = path.Path

_ENV = unit.create_test_env(_ENV)

describe('llx.path free functions', function()
  describe('is_absolute', function()
    it('should recognize absolute paths', function()
      expect(path.is_absolute('/foo/bar')).to.be_true()
    end)

    it('should reject relative paths', function()
      expect(path.is_absolute('foo/bar')).to.be_false()
      expect(path.is_absolute('./foo')).to.be_false()
      expect(path.is_absolute('')).to.be_false()
    end)
  end)

  describe('join', function()
    it('should join simple components', function()
      expect(path.join('/foo', 'bar', 'baz')).to.be_equal_to('/foo/bar/baz')
    end)

    it('should handle relative joins', function()
      expect(path.join('foo', 'bar')).to.be_equal_to('foo/bar')
    end)

    it('should reset when an absolute component appears', function()
      expect(path.join('/foo', '/bar')).to.be_equal_to('/bar')
    end)

    it('should not duplicate slashes', function()
      expect(path.join('/foo/', 'bar')).to.be_equal_to('/foo/bar')
    end)

    it('should accept a single argument', function()
      expect(path.join('/foo')).to.be_equal_to('/foo')
    end)

    it('should reject non-string arguments', function()
      expect(function() path.join('/foo', 42) end).to.throw()
    end)
  end)

  describe('split', function()
    it('should split into dirname and basename', function()
      local d, n = path.split('/foo/bar.txt')
      expect(d).to.be_equal_to('/foo')
      expect(n).to.be_equal_to('bar.txt')
    end)

    it('should treat a root file as dirname /', function()
      local d, n = path.split('/foo')
      expect(d).to.be_equal_to('/')
      expect(n).to.be_equal_to('foo')
    end)

    it('should treat a bare name as empty dirname', function()
      local d, n = path.split('foo')
      expect(d).to.be_equal_to('')
      expect(n).to.be_equal_to('foo')
    end)
  end)

  describe('splitext', function()
    it('should split stem from extension', function()
      local s, ext = path.splitext('/a/b.txt')
      expect(s).to.be_equal_to('/a/b')
      expect(ext).to.be_equal_to('.txt')
    end)

    it('should leave hidden-file leading dot alone', function()
      local s, ext = path.splitext('/foo/.bashrc')
      expect(s).to.be_equal_to('/foo/.bashrc')
      expect(ext).to.be_equal_to('')
    end)

    it('should handle no extension', function()
      local s, ext = path.splitext('/foo/bar')
      expect(s).to.be_equal_to('/foo/bar')
      expect(ext).to.be_equal_to('')
    end)

    it('should take only the last extension', function()
      local s, ext = path.splitext('/x/archive.tar.gz')
      expect(s).to.be_equal_to('/x/archive.tar')
      expect(ext).to.be_equal_to('.gz')
    end)
  end)

  describe('normalize', function()
    it('should collapse single dots', function()
      expect(path.normalize('/a/./b/./c')).to.be_equal_to('/a/b/c')
    end)

    it('should collapse double dots', function()
      expect(path.normalize('/a/b/../c')).to.be_equal_to('/a/c')
    end)

    it('should not go above root for absolute paths', function()
      expect(path.normalize('/../a')).to.be_equal_to('/a')
    end)

    it('should preserve leading ..  for relative paths', function()
      expect(path.normalize('../a')).to.be_equal_to('../a')
    end)

    it('should collapse multiple slashes', function()
      expect(path.normalize('/a//b///c')).to.be_equal_to('/a/b/c')
    end)

    it('should return . for empty path', function()
      expect(path.normalize('')).to.be_equal_to('.')
    end)

    it('should return / for root', function()
      expect(path.normalize('/')).to.be_equal_to('/')
    end)
  end)
end)

describe('Path class', function()
  describe('construction', function()
    it('should wrap a string', function()
      expect(tostring(Path('/a/b'))).to.be_equal_to('/a/b')
    end)

    it('should accept another Path (identity)', function()
      local p = Path('/x/y')
      expect(tostring(Path(p))).to.be_equal_to('/x/y')
    end)

    it('should reject non-strings', function()
      expect(function() Path(42) end).to.throw()
    end)
  end)

  describe('navigation', function()
    it(':parent returns a Path of the directory', function()
      expect(tostring(Path('/a/b/c'):parent())).to.be_equal_to('/a/b')
    end)

    it(':name returns the final component', function()
      expect(Path('/a/b.txt'):name()).to.be_equal_to('b.txt')
    end)

    it(':stem returns the name without suffix', function()
      expect(Path('/a/b.txt'):stem()).to.be_equal_to('b')
    end)

    it(':stem leaves hidden files intact', function()
      expect(Path('/a/.bashrc'):stem()).to.be_equal_to('.bashrc')
    end)

    it(':suffix returns the trailing extension', function()
      expect(Path('/a/b.txt'):suffix()).to.be_equal_to('.txt')
    end)

    it(':suffix is empty for no extension', function()
      expect(Path('/a/b'):suffix()).to.be_equal_to('')
    end)

    it(':suffixes returns all extensions', function()
      local s = Path('archive.tar.gz'):suffixes()
      expect(#s).to.be_equal_to(2)
      expect(s[1]).to.be_equal_to('.tar')
      expect(s[2]).to.be_equal_to('.gz')
    end)

    it(':parts returns components including root marker', function()
      local p = Path('/a/b/c'):parts()
      expect(p[1]).to.be_equal_to('/')
      expect(p[2]).to.be_equal_to('a')
      expect(p[4]).to.be_equal_to('c')
    end)
  end)

  describe('joining', function()
    it(':join appends one component', function()
      expect(tostring(Path('/a'):join('b'))).to.be_equal_to('/a/b')
    end)

    it(':join appends multiple components', function()
      expect(tostring(Path('/a'):join('b', 'c'))).to.be_equal_to('/a/b/c')
    end)

    it('/ operator appends a component', function()
      expect(tostring(Path('/a') / 'b' / 'c.txt'))
        .to.be_equal_to('/a/b/c.txt')
    end)

    it('/ operator works with strings on either side', function()
      expect(tostring(Path('/a') / 'b')).to.be_equal_to('/a/b')
    end)
  end)

  describe('with_name and with_suffix', function()
    it('with_name replaces the final component', function()
      expect(tostring(Path('/a/b.txt'):with_name('c.lua')))
        .to.be_equal_to('/a/c.lua')
    end)

    it('with_suffix replaces the extension', function()
      expect(tostring(Path('/a/b.txt'):with_suffix('.lua')))
        .to.be_equal_to('/a/b.lua')
    end)

    it('with_suffix("") strips the extension', function()
      expect(tostring(Path('/a/b.txt'):with_suffix('')))
        .to.be_equal_to('/a/b')
    end)
  end)

  describe('normalize', function()
    it(':normalize collapses path traversal', function()
      expect(tostring(Path('/a/b/../c'):normalize()))
        .to.be_equal_to('/a/c')
    end)
  end)

  describe('__eq and __hash', function()
    it('paths with same normal form compare equal', function()
      expect(Path('/a/b') == Path('/a/./b')).to.be_true()
    end)

    it('different normal forms compare unequal', function()
      expect(Path('/a/b') == Path('/a/c')).to.be_false()
    end)

    it('equal paths hash equal', function()
      local hash = require 'llx.hash'.hash
      expect(hash(Path('/a/b'))).to.be_equal_to(hash(Path('/a/./b')))
    end)

    it('paths are usable as HashTable keys', function()
      local ht = llx.HashTable()
      ht[Path('/foo/bar')] = 'value'
      expect(ht[Path('/foo/./bar')]).to.be_equal_to('value')
    end)
  end)

  describe('filesystem helpers', function()
    -- Use os.tmpname for a path we can safely write to and clean up.
    local tmp

    it('write_text + read_text round-trip', function()
      tmp = os.tmpname()
      local p = Path(tmp)
      p:write_text('hello world')
      expect(p:read_text()).to.be_equal_to('hello world')
      os.remove(tmp)
    end)

    it('exists returns true for an existing file', function()
      tmp = os.tmpname()
      local p = Path(tmp)
      p:write_text('x')
      expect(p:exists()).to.be_true()
      os.remove(tmp)
    end)

    it('exists returns false for a missing file', function()
      local p = Path('/this/does/not/exist/llx/test/probably')
      expect(p:exists()).to.be_false()
    end)

    it('write_bytes + read_bytes preserves binary content', function()
      tmp = os.tmpname()
      local p = Path(tmp)
      local bytes = string.char(0, 1, 2, 3, 255)
      p:write_bytes(bytes)
      expect(p:read_bytes()).to.be_equal_to(bytes)
      os.remove(tmp)
    end)

    it('read_text raises on missing file', function()
      local p = Path('/missing/file/that/does/not/exist')
      expect(function() p:read_text() end).to.throw()
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end
