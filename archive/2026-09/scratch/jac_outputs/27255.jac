"""Scale maxval according to level between 0 and PARAMETER_MAX."""
def int_parameter(level: int, maxval: int) -> int {
    return int(level * maxval / 10);
}