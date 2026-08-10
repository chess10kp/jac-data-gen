glob NOTE_MASK = 0x3F;
glob INSTR_HI_MASK = 0xC0;
glob COMMAND_MASK = 0x0F;

"""return data read from file (short - MMD0 - format) as note event information
    """
def mmd0_decode(data: bytes) -> tuple[int, int, int, int] {
    note_number = data[0] & NOTE_MASK;
    instr_hi = (data[0] & INSTR_HI_MASK) >> 2;
    instr_lo = data[1] >> 4;
    instr_number = instr_hi + instr_lo;
    command = data[1] & COMMAND_MASK;
    return (note_number, instr_number, command, data[2]);
}