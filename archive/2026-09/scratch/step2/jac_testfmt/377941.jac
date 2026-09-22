"""
  Takes a CSIM program as a list of instructions (strings),
  and maps it to a SCAMP5 program.
  program: list of instructions, ['instr1', 'instr2', '// comment', ...]. Should
    be the exact output of AUKE (we here rely on its specific syntax, such as
    whitespace location etc.)
  doubleShifts: boolean, if True shifting instructions are replaced
    by double_shifting instructions (see macros in .hpp file)
  """
def csim_to_scamp5(program: Any, doubleShifts: Any = False) -> object {
    outputProgram = [];
    if doubleShifts {
        shiftPrefix = 'double_';
    } else {
        shiftPrefix = '';
    }
    for instr in program {
        if instr.startswith('_transform') {
            instr = '// ' + instr;
        } elif (
            instr.startswith('// north')
            or instr.startswith('// east')
            or instr.startswith('// south')
            or instr.startswith('// west')
        ) {
            instr = shiftPrefix + instr[3:];
        } elif instr.startswith('// div2') {
            instr = instr[3:];
            if (instr[5] == instr[8]) {
                instr = 'div2_inplace' + instr[4:];
            }
        } elif instr.startswith('neg') {
            if (instr[4] == instr[7]) {
                instr = 'neg_inplace' + instr[3:];
            }
        } elif instr.startswith('add') {
            if (instr[7] == instr[10]) {
                instr = 'add_twice' + instr[3:];
            } elif (instr[4] == instr[10]) {
                instr = instr[:7] + instr[10] + instr[8:10] + instr[7] + instr[11:];
            }
        } elif instr.startswith('sub') {
            if (instr[4] == instr[10]) {
                instr = 'sub_inplace' + instr[3:];
            }
        }
        outputProgram.append(instr);
    }
    return outputProgram;
}

test "t0" {
    assert (
        csim_to_scamp5(['a = 5', 'b = 6', 'c = a + b']) == [
            'a = 5',
            'b = 6',
            'c = a + b'
        ]
    );;
}

test "t1" {
    assert (csim_to_scamp5(['// div2 0 0 0 0 0 0']) == ['div2 0 0 0 0 0 0']);;
}

test "t2" {
    assert (csim_to_scamp5(['a = 5', 'b = 6', 'c = a']) == ['a = 5', 'b = 6', 'c = a']);;
}

test "t3" {
    assert (csim_to_scamp5(['neg: 1, 1, 1']) == ['neg_inplace: 1, 1, 1']);;
}

test "t4" {
    assert (csim_to_scamp5(['// neg(1, 0)']) == ['// neg(1, 0)']);;
}

test "t5" {
    assert (csim_to_scamp5(['// rotate(15, 0, 0, 0)']) == ['// rotate(15, 0, 0, 0)']);;
}

test "t6" {
    assert (csim_to_scamp5(['// div2: 1, 1, 1']) == ['div2_inplace: 1, 1, 1']);;
}

test "t7" {
    assert (csim_to_scamp5(['a = 5', 'b = 6', 'c = b']) == ['a = 5', 'b = 6', 'c = b']);;
}

test "t8" {
    assert (csim_to_scamp5(['_transform(2, 3)']) == ['// _transform(2, 3)']);;
}

test "t9" {
    assert (
        csim_to_scamp5(['mul_inplace', '1', '2', '3'], False) == [
            'mul_inplace',
            '1',
            '2',
            '3'
        ]
    );;
}

test "t10" {
    assert (csim_to_scamp5(['// div2_inplace a b']) == ['div2_inplace a b']);;
}

test "t11" {
    assert (csim_to_scamp5(['// div2 0 1 0 0 0 1']) == ['div2 0 1 0 0 0 1']);;
}

test "t12" {
    assert (
        csim_to_scamp5(['_transform(0,1);', 'sub_inplace(i,j);', 'add_twice(i,i);']) == [
            '// _transform(0,1);',
            'sub_inplace(i,j);',
            'add_twice(i,i);'
        ]
    );;
}

test "t13" {
    assert (
        csim_to_scamp5(['add: 1, 1, 1, 2, 2, 2']) == ['add_twice: 1, 1, 1, 2, 2, 2']
    );;
}

test "t14" {
    assert (
        csim_to_scamp5(['a = 5', 'b = 6', 'c = a - b']) == [
            'a = 5',
            'b = 6',
            'c = a - b'
        ]
    );;
}

test "t15" {
    assert (csim_to_scamp5(['neg(x, x)']) == ['neg_inplace(x, x)']);;
}

test "t16" {
    assert (
        csim_to_scamp5(['neg_inplace(i,j);', 'neg(i,k);']) == [
            'neg_inplace(i,j);',
            'neg(i,k);'
        ]
    );;
}

test "t17" {
    assert (csim_to_scamp5(['// neg_inplace(1, 0)']) == ['// neg_inplace(1, 0)']);;
}

test "t18" {
    assert (csim_to_scamp5(['north(x, y)']) == ['north(x, y)']);;
}

test "t19" {
    assert (csim_to_scamp5(['add_twice 0 0 1 0 0 1']) == ['add_twice 0 0 1 0 0 1']);;
}
