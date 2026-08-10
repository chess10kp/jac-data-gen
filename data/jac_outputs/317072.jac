"""Returns True if the two strings are equal, False otherwise."""
def constant_time_compare(val1: bytes, val2: bytes) -> bool {
    if len(val1) != len(val2) {
        return False;
    }
    result = 0;
    for (x, y) in zip(val1, val2) {
        result |= x ^ y;
    }
    return result == 0;
}