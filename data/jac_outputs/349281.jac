""" Return (opcode, (mode_1st, mode_2nd, mode_3rd)) from an instruction """
def opcode_modes(instruction: int) -> tuple[int, tuple[int, int, int]] {
    digits = f"{instruction:05}";
    opcode = int(digits[-2:]);
    modes = (int(digits[-3]), int(digits[-4]), int(digits[-5]));
    return (opcode, modes);
}