"""Return a list of the set binary flags. For example:  [2, 16, 64]  """
def flags(value: int) -> list[int] {
    flags = [];
    while value {
        _current_bit = value & (~value + 1);
        flags.append(_current_bit);
        value ^= _current_bit;
    }
    return flags;
}