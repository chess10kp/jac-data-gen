"""rol(int_type, size, offset) -> int

    Returns the value of int_type rotated left by (offset mod size) bits.
    """
def rol(int_type: int, size: int, offset: int) -> int {
    mask = (1 << size) - 1;
    offset %= size;
    left = (int_type << offset) & mask;
    circular = (int_type & mask) >> (size - offset);
    return left | circular;
}