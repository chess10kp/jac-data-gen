"""Converts a boolean value to an integer of 0 or 1."""
def _int_from_bool(boolean_value: bool) -> int {
    if boolean_value {
        return 1;
    }
    return 0;
}