import operator
from functools import *

class NoteNames:
  def __getitem__(self, key):
    note_names = 'CDEFGAB'
    return note_names[key % 12] + str(key // 12 + 4)

def rotate(l, n):
  return l[-n % len(l):] + l[:-n % len(l)]

def append(l, e):
  return l + [l[-1] + e]

def lmap(*args):
  return list(map(*args))

def tmap(*args):
  return tuple(map(*args))

def smap(*args):
  return ''.join(list(map(*args)))

def inversion(chord, ordinal):
  rotated_chord = chord
  for _ in range(ordinal):
    rotated_chord = rotate(list(rotated_chord), -1)
    rotated_chord[-1] += octave_half_steps
  return tuple(rotated_chord)
  
def tones_from_steps(steps):
  return tuple(reduce(append, steps, [C4]))

def create_chord(tones, names):
  return {
      'names': names,
      'tones': tones
  }

note_names = NoteNames()

superscipts = '⁰¹²³⁴⁵⁶⁷⁸⁹'
subscripts = '₀₁₂₃₄₅₆₇₈₉'

# Chord modifiers
major_annotation = 'maj'
minor_annotation = 'min'
diminished_annotation = 'dim'
augmented_annotation = 'aug'
diminished_symbol = '°'
augmented_symbol = '⁺'
half_diminished_symbol = '⦰'

# Made up by alex because the notation lacks this
def inversion_symbol(i):
  result = '|' + smap(lambda c: subscripts[ord(c) - ord('0')], str(i))
  return result

# Note modifiers
natural = '♮'
flat = '♭'
double_flat = '𝄫'
sharp = '♯'
double_sharp = '𝄪'

octave_half_steps = 12
whole_step = 2
half_step = 1
C4 = 0

ionian_mode = [whole_step, whole_step, half_step, whole_step, whole_step, whole_step, half_step]
dorian_mode = rotate(ionian_mode, -1)
phrygian_mode = rotate(ionian_mode, -2)
lydian_mode = rotate(ionian_mode, -3)
mixolydian_mode = rotate(ionian_mode, -4)
aeolian_mode = rotate(ionian_mode, -5)
locrian_mode = rotate(ionian_mode, -6)

major_scale_steps = ionian_mode

major_triad_steps = [4, 3]
minor_triad_steps = [3, 4]
diminished_triad_steps = [3, 3]
augmented_triad_steps = [4, 4]

major_seventh_steps = [4, 3, 4]
dominant_seventh_steps = [4, 3, 3]
minor_seventh_steps = [3, 4, 3]
diminished_seventh_steps = [3, 3, 3]
half_diminished_seventh_steps = [3, 3, 4]
major_minor_seventh = [3, 4, 4]
augmented_major_seventh = [4, 4, 3]

note_names = [
    ['♯B', 'C', '𝄫D'], 
    ['♯C', '♭D'], 
    ['𝄪C', 'D', '𝄫E'], 
    ['♯D', '♭E'], 
    ['𝄪D', 'E', '♭F'], 
    ['♯E', 'F', '𝄫G'], 
    ['♯E', '♭F'], 
    ['𝄪F', 'G', '𝄫A'], 
    ['♯F', '♭G'], 
    ['𝄪G', 'A', '𝄫B'], 
    ['♯G', '♭A'], 
    ['𝄪A', 'B', '♭C'], 
    ['♯A', '♭B'], 
]

# major_roman_numerals = ['I', '', 'II', '', 'III', 'IV', '', 'V', '', 'VI', '', 'VII']
# minor_roman_numerals = [numeral.lower() for numeral in major_roman_numerals]

def letter_to_numeral(name):
  replacements = [('C', 'I'), ('D', 'II'), ('E', 'III'), ('F', 'IV'), ('G', 'V'), ('A', 'VI'), ('B', 'VII')]
  name = name[::-1]
  for replacement in replacements:
    letter, numeral = replacement
    name = name.replace(letter, numeral)
  return name

major_roman_numerals = [[letter_to_numeral(name) for name in names] for names in note_names]
minor_roman_numerals = [[numeral.lower() for numeral in numerals] for numerals in major_roman_numerals]

# Common Triads
major_names = lmap(lambda names: names + lmap(lambda name: name + major_annotation, names), note_names)
for names, numerals in zip(major_names, major_roman_numerals):
  names.extend(numerals)

minor_names = lmap(lambda names: lmap(lambda name: name + minor_annotation, names), note_names)
for names, numerals in zip(minor_names, minor_roman_numerals):
  names.extend(numerals)

diminished_names = lmap(lambda names: lmap(lambda name: name + diminished_annotation, names), note_names)
diminished_names = lmap(lambda existing_names, names: existing_names + lmap(lambda name: name + diminished_symbol, names), diminished_names, note_names)
for names, numerals in zip(diminished_names, major_roman_numerals):
  names.extend([numeral + diminished_symbol for numeral in numerals])

augmented_names = lmap(lambda names: lmap(lambda name: name + augmented_annotation, names), note_names)
augmented_names = lmap(lambda existing_names, names: existing_names + lmap(lambda name: name + augmented_symbol, names), augmented_names, note_names)
for names, numerals in zip(augmented_names, major_roman_numerals):
  names.extend([numeral + augmented_symbol for numeral in numerals])

major_chord = create_chord(tones_from_steps(major_triad_steps), major_names)
minor_chord = create_chord(tones_from_steps(minor_triad_steps), minor_names)
diminished_chord = create_chord(tones_from_steps(diminished_triad_steps), diminished_names)
augmented_chord = create_chord(tones_from_steps(augmented_triad_steps), augmented_names)
common_chords = [major_chord, minor_chord, diminished_chord, augmented_chord]

# Seventh chords
major_seventh_names = lmap(lambda names: lmap(lambda name: name + major_annotation + superscipts[7], names), note_names)
dominant_seventh_names = lmap(lambda names: lmap(lambda name: name + superscipts[7], names), note_names)
minor_seventh_names = lmap(lambda names: lmap(lambda name: name + 'ᵐ' + superscipts[7], names), note_names)
diminished_seventh_names = lmap(lambda names: lmap(lambda name: name + diminished_annotation + superscipts[7], names), note_names)
half_diminished_seventh_names = lmap(lambda names: lmap(lambda name: name + half_diminished_symbol + superscipts[7], names), note_names)

major_seventh_chord = create_chord(tones_from_steps(major_seventh_steps), major_seventh_names)
dominant_seventh_chord = create_chord(tones_from_steps(dominant_seventh_steps), dominant_seventh_names)
minor_seventh_chord = create_chord(tones_from_steps(minor_seventh_steps), minor_seventh_names)
diminished_seventh_chord = create_chord(tones_from_steps(diminished_seventh_steps), diminished_seventh_names)
half_diminished_seventh_chord = create_chord(tones_from_steps(half_diminished_seventh_steps), half_diminished_seventh_names)
seventh_chords = [major_seventh_chord, dominant_seventh_chord, minor_seventh_chord, diminished_seventh_chord, half_diminished_seventh_chord]

base_chords = common_chords + seventh_chords

# I fear science has gone too far. 
inverted_chords = [create_chord(inversion(chord['tones'], i), [[name + inversion_symbol(i) for name in names] for names in chord['names']]) for chord in seventh_chords for i in list(range(1, len(chord['tones'])))]

all_chords = base_chords + inverted_chords

chord_tone_names = {}
names_to_chord_tones = {}
normalized_tones = set()
normalized_intervals = set()
def add_chord(tones, name):
  names = chord_tone_names.setdefault(tones, [])
  if name not in names:
    names.append(name)
  names_to_chord_tones[name] = tones
  tonic = tones[0]
  tonic_chord = (tonic,) * len(chord['tones'])
  normalized = tmap(lambda c, t: c - t, tones, tonic_chord)
  normalized_tones.add(normalized)
  interval = []
  for i in range(1, len(normalized)):
    interval.append(normalized[i] - normalized[i-1])
  normalized_intervals.add(tuple(interval))

def add_scales(chord):
  for i, names in enumerate(chord['names']):
    transposition = (i,) * len(chord['tones'])
    new_tones = tuple(map(operator.add, chord['tones'], transposition))
    while all(tone >= octave_half_steps for tone in new_tones):
      new_tones = tmap(lambda tone: tone - octave_half_steps, new_tones)
    for name in names:
      add_chord(new_tones, name)

for chord in all_chords:
  add_scales(chord)

for v in sorted([tones for tones in normalized_intervals]):
  print(v)
# for k, v in chord_tone_names.items():
#   print(str(k) + ': ' + str(v))
# print('====')
# for k, v in names_to_chord_tones.items():
#   print(str(k) + ': ' + str(v))
# print('====')
