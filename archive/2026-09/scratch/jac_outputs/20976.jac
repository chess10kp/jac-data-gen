"""Scale a value between 0 and maxval and return as an int."""
def int_parameter(level: int, maxval: int) -> int {
    return int(level * maxval / 10);
}