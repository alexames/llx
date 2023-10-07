from fractions import Fraction

def to_cents(ratio):
  return int((float(ratio) - 1.0) * 1000.0)

notes = []
start = -6
for exponent in range(start, start+13):
  ratio = Fraction(3, 2)
  ratio = ratio ** exponent
  value = float(ratio)
  while value <= 1:
    ratio = Fraction(ratio.numerator * 2, ratio.denominator)
    value = float(ratio)
  while value >= 2:
    ratio = Fraction(ratio.numerator, ratio.denominator * 2)
    value = float(ratio)
  notes.append(ratio)

sorted_notes = sorted(notes, key=lambda ratio: float(ratio))

for ratio in sorted_notes:
  print "%s/%s = %s" % (ratio.numerator, ratio.denominator, to_cents(ratio))
