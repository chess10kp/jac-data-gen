def csim_to_scamp5(program, doubleShifts=False):
  """
  Takes a CSIM program as a list of instructions (strings),
  and maps it to a SCAMP5 program.
  program: list of instructions, ['instr1', 'instr2', '// comment', ...]. Should
    be the exact output of AUKE (we here rely on its specific syntax, such as
    whitespace location etc.)
  doubleShifts: boolean, if True shifting instructions are replaced
    by double_shifting instructions (see macros in .hpp file)
  """
  outputProgram = []

  # Create prefix for shifting instructions
  if doubleShifts:
    shiftPrefix = 'double_'
  else:
    shiftPrefix = ''

  # Iterate on instructions
  for instr in program:

    # Remove _transform instructions
    if instr.startswith('_transform'):
        instr = '// ' + instr

    # Uncomment shifting instructions, and
    # add prefix if necessary
    elif (instr.startswith('// north')
          or instr.startswith('// east')
          or instr.startswith('// south')
          or instr.startswith('// west')):
      instr = shiftPrefix + instr[3:]

    # Uncomment division instruction
    elif instr.startswith('// div2'):
      instr = instr[3:]
      # Differentiate between inplace division,
      # and to a different target register
      if instr[5] == instr[8]:
        instr = 'div2_inplace' + instr[4:]

    # neg: differentiate between inplace or to a different target
    elif instr.startswith('neg'):
      if instr[4] == instr[7]:
        instr = 'neg_inplace' + instr[3:]

    # add: both sources different, and target and source2 different
    elif instr.startswith('add'):
      # If both sources are the same
      if instr[7] == instr[10]:
        instr = 'add_twice' + instr[3:]
      # If target = source2, swap them
      elif instr[4] == instr[10]:
        instr = instr[:7] + instr[10] + instr[8:10] + instr[7] + instr[11:]

    # sub: target and source2 different
    elif instr.startswith('sub'):
      if instr[4] == instr[10]:
        instr = 'sub_inplace' + instr[3:]

    outputProgram.append(instr)
  return outputProgram

assert csim_to_scamp5(
    ['a = 5', 'b = 6', 'c = a + b']) == ['a = 5', 'b = 6', 'c = a + b']
assert csim_to_scamp5(['// div2 0 0 0 0 0 0']) == ['div2 0 0 0 0 0 0']
assert csim_to_scamp5(
    ['a = 5', 'b = 6', 'c = a']) == ['a = 5', 'b = 6', 'c = a']
assert csim_to_scamp5(['neg: 1, 1, 1']) == ['neg_inplace: 1, 1, 1']
assert csim_to_scamp5(['// neg(1, 0)']) == ['// neg(1, 0)']
assert csim_to_scamp5(['// rotate(15, 0, 0, 0)']) == ['// rotate(15, 0, 0, 0)']
assert csim_to_scamp5(['// div2: 1, 1, 1']) == ['div2_inplace: 1, 1, 1']
assert csim_to_scamp5(
    ['a = 5', 'b = 6', 'c = b']) == ['a = 5', 'b = 6', 'c = b']
assert csim_to_scamp5( ['_transform(2, 3)'] ) == [ '// _transform(2, 3)']
assert csim_to_scamp5(
  ['mul_inplace', '1', '2', '3'],
  False) == ['mul_inplace', '1', '2', '3']
assert csim_to_scamp5(['// div2_inplace a b']) == \
  ['div2_inplace a b']
assert csim_to_scamp5(['// div2 0 1 0 0 0 1']) == ['div2 0 1 0 0 0 1']
assert csim_to_scamp5(
  ['_transform(0,1);','sub_inplace(i,j);', 'add_twice(i,i);']) == \
  ['// _transform(0,1);','sub_inplace(i,j);', 'add_twice(i,i);']
assert csim_to_scamp5(['add: 1, 1, 1, 2, 2, 2']) == ['add_twice: 1, 1, 1, 2, 2, 2']
assert csim_to_scamp5(
    ['a = 5', 'b = 6', 'c = a - b']) == ['a = 5', 'b = 6', 'c = a - b']
assert csim_to_scamp5( ['neg(x, x)'] ) == [ 'neg_inplace(x, x)']
assert csim_to_scamp5(
  ['neg_inplace(i,j);', 'neg(i,k);']) == \
  ['neg_inplace(i,j);', 'neg(i,k);']
assert csim_to_scamp5(['// neg_inplace(1, 0)']) == ['// neg_inplace(1, 0)']
assert csim_to_scamp5( ['north(x, y)'] ) == [ 'north(x, y)']
assert csim_to_scamp5(['add_twice 0 0 1 0 0 1']) == ['add_twice 0 0 1 0 0 1']
