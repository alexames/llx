from argparse import ArgumentParser
import re
import subprocess
import sys

_DIFF_COMMAND = 'diff'

class Git:
  def __init__(self, git_binary='git'):
    self._git_binary = git_binary

  def diff(self, ref1, ref2=None):
    ref_string = ref1 if not ref2 else (ref1 + '..' + ref2)
    result = subprocess.run([self._git_binary, _DIFF_COMMAND, ref_string],
                            capture_output=True, check=False)
    return result.stdout.decode('utf-8', errors='replace')

class DiffParser:
  def __init__(self, diff_str, actions):
    self._generator = iter(diff_str.splitlines())
    self._current_line = None
    self._current_left_filename = None
    self._current_right_filename = None
    self._consume_line()
    self._actions = actions

  def line(self):
    return self._current_line

  def parse(self):
    try:
      self._parseDiff()
    except AssertionError:
      print('ERROR: ', self._current_line)
      raise
    except StopIteration:
      pass

  def _consume_line(self):
    line = self.line()
    self._current_line = next(self._generator)
    return line

  def _match_prefix(self, prefix):
    if self.line().startswith(prefix):
      self._consume_line()
      return True
    else:
      return False

  def _parseNewFileIndex(self):
    assert self._match_prefix('index')
    self._parseLeftFilename()

  def _parseLeftFilename(self):
    prefix = '--- '
    assert self.line().startswith(prefix)
    self._current_left_filename = self._consume_line()[len(prefix):]
    self._parseRightFilename()
    
  def _parseRightFilename(self):    
    prefix = '+++ '
    assert self.line().startswith(prefix)
    self._current_right_filename = self._consume_line()[len(prefix):]
    self._parseLineNumbers()

  def _parseDiffRange(self, range_str):
    match = re.match(r'[-+](\d+),(\d+)', range_str)
    assert match
    return (int(match.group(1)), int(match.group(2)))

  def _parseLineNumbers(self):
    assert self.line().startswith('@@')
    _, left_range, right_range, _, *_ = self._consume_line().split()
    self._parseLines(self._parseDiffRange(left_range), 
                     self._parseDiffRange(right_range))

  def _runAction(self, index, filename, linenumber, line):
    action = self._actions[index]
    if action:
      action(filename, linenumber, line[1:])

  def _parseLines(self, left_range, right_range):
    left_start, left_length = left_range
    right_start, right_length = right_range
    left_iter = left_start
    right_iter = right_start
    while right_iter < right_start + right_length:
      line = self._consume_line()
      prefix = line[0]
      if prefix == '-':
        left_iter += 1
        self._runAction(0, self._current_left_filename, left_iter, line)
      elif prefix == '+':
        right_iter += 1
        self._runAction(1, self._current_right_filename, right_iter, line)
      elif prefix == ' ':
        left_iter += 1
        right_iter += 1
        # Not sure if the iter maters here.
        self._runAction(2, self._current_left_filename, left_iter, line)
      else:
        assert False
    assert left_iter == left_start + left_length
    self._parseNewFileOrHunk()

  def _parseNewFileOrHunk(self):
    if self.line().startswith('diff'):
      self._parseDiff()
    elif self.line().startswith('@@'):
      self._parseLineNumbers()
    else:
      assert False
    
  def _parseDiff(self):
    assert self.line().startswith('diff')
    _, _, left_file, right_file = self._consume_line().split()
    prefix = 'b/'
    local_path = right_file[len(prefix):]
    self._parseIndex()

  def _parseIndex(self):
    if self._match_prefix('index'):
      self._parseLeftFilename()
    elif self.line().startswith('new file'):
      self._parseNewFileIndex()
    else:
      assert False

def parseDiffOutput(lines, actions):
  DiffParser(lines, actions).parse()

def printIfMatches(filename, linenumber, line, regex):
  if re.search(regex, line):
    print(f'{filename}:{linenumber}:{line}')

def main(args):
  assert len(args) == 4

  parser = ArgumentParser(description='Grep for the diff that removed code.')
  git = Git()
  lines = git.diff(args[1], args[2])
  regex = re.compile(args[3])
  def printRegexMatches(filename, linenumber, line):
    printIfMatches(filename, linenumber, line, regex)

  parseDiffOutput(lines, (printRegexMatches, None, None))

if __name__ == '__main__':
  main(sys.argv)