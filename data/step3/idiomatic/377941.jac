"""Map a CSIM program (AUKE output) to a SCAMP5 program.

When double_shifts is True, shifting instructions are rewritten to their
double_ variants.
"""
def csim_to_scamp5(program: list[str], double_shifts: bool = False) -> list[str] {
    output_program: list[str] = [];
    shift_prefix = 'double_' if double_shifts else '';
    for instr in program {
        if instr.startswith('_transform') {
            instr = '// ' + instr;
        } elif instr.startswith(('// north', '// east', '// south', '// west')) {
            instr = shift_prefix + instr[3:];
        } elif instr.startswith('// div2') {
            instr = instr[3:];
            if instr[5] == instr[8] {
                instr = 'div2_inplace' + instr[4:];
            }
        } elif instr.startswith('neg') {
            if instr[4] == instr[7] {
                instr = 'neg_inplace' + instr[3:];
            }
        } elif instr.startswith('add') {
            if instr[7] == instr[10] {
                instr = 'add_twice' + instr[3:];
            } elif instr[4] == instr[10] {
                instr = instr[:7] + instr[10] + instr[8:10] + instr[7] + instr[11:];
            }
        } elif instr.startswith('sub') {
            if instr[4] == instr[10] {
                instr = 'sub_inplace' + instr[3:];
            }
        }
        output_program.append(instr);
    }
    return output_program;
}
