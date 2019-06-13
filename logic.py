import sys

# todo
def int_to_character(i):
  pass

def digits_in_base(base, digit_count, value):
  digits = [0] * digit_count
  current_place = digit_count - 1
  while value > 0:
    digits[current_place] = value % base
    value = value // base
    current_place -= 1
  return tuple(digits)

def is_commutative(truth_table):
  for key in truth_table:
    if truth_table[key] != truth_table[key[::-1]]:
      return False
  return True

def is_associative(truth_table):
  for a in range(2):
    for b in range(2):
      for c in range(2):
        ab = truth_table[(a, b)]
        bc = truth_table[(b, c)]
        if truth_table[(ab, c)] != truth_table[(a, bc)]:
          return False
    return True


def is_distributive(truth_table):
  pass
def is_idempotent(truth_table):
  for a in range(2):
    if truth_table[(a, a)] != a:
      return False
  return True

def is_monotonic(truth_table):
  pass
def is_truth_preserving(truth_table):
  pass
def is_false_preserving(truth_table):
  pass

class Test():
  def __init__(self, name, abbreviation, test):
    self.name = name
    self.abbreviation = abbreviation
    self.test = test

  def run_test(self, truth_table):
    return self.test(truth_table)

table_names = {
  (0, 0, 0, 0): " 0 ",
  (0, 0, 0, 1): " & ",
  (0, 0, 1, 0): "~<-",
  (0, 0, 1, 1): " A ",
  (0, 1, 0, 0): "~->",
  (0, 1, 0, 1): " B ",
  (0, 1, 1, 0): "~= ",
  (0, 1, 1, 1): " | ",
  (1, 0, 0, 0): "~| ",
  (1, 0, 0, 1): " = ",
  (1, 0, 1, 0): "~B ",
  (1, 0, 1, 1): "-> ",
  (1, 1, 0, 0): "~A ",
  (1, 1, 0, 1): "<- ",
  (1, 1, 1, 0): "~& ",
  (1, 1, 1, 1): " 1 ",
}

def logic_table(write, base, tests=[]):
  combinations = base * base

  operand_pairs = []
  for i in xrange(combinations):
    operand_pairs.append(digits_in_base(base, 2, i))

  # Header
  write("| AOB | ")
  for operand_pair in operand_pairs:
    write(''.join([str(operands) for operands in operand_pair]))
    write(' ')
  for test in tests:
    write('| ')
    write(test.abbreviation)
    write(' ')
  write('|\n')

  # Divider
  write('|-----|-')
  write('---' * combinations)
  for test in tests:
    column_width = len(test.abbreviation) + 2
    write('|')
    write('-' * column_width)
  write('|\n')
  
  # Results
  for i in xrange(base**combinations):
    digits = digits_in_base(base, combinations, i)

    # Precompute truth table to help with tests
    truth_table = {}
    for result_index, operand_pair in enumerate(operand_pairs):
      truth_table[operand_pair] = digits[result_index]

    # Print truth values
    write('| ')
    write(table_names.get(digits, '   '))
    write(' |  ')
    write('  '.join([str(digit) for digit in digits]))
    write(' ')

    # Tests
    for test in tests:
      column_width = len(test.abbreviation) + 2
      space_before = column_width // 2
      space_after = (column_width - 1) // 2
      write('|')
      write(' ' * space_before)
      write('1' if test.run_test(truth_table) else '0')
      write(' ' * space_after)

    write('|\n')

tests = [
  # Test("Commutative", "Com", is_commutative),
  # Test("Associative", "Asc", is_associative),
  # Test("Idempotent", "Idm", is_idempotent),
]
def no_write(s):
  pass

write_fn = sys.stdout.write
# write_fn = no_write

logic_table(write_fn, 3, tests)