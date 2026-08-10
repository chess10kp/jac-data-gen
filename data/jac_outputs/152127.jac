"""
Converts given value to an integer or returns 0 if it fails.
"""
def to_int_or_zero(value: str | int | float | bool) -> int {
    try {
        return int(value);
    } except ValueError {
        return 0;
    }
}