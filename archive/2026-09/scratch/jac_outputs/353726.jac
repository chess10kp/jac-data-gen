""" Convert an 8-bit word of 2's complement into an int. """
def tc_to_int(value: int) -> int {
    assert 0 <= value <= 255;
    sign = value & (1 << 7);
    if sign != 0 {
        value -= 1 << 8;
    }
    return value;
}