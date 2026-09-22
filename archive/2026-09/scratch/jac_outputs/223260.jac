"""Check whether the given string is an integer or not."""
def is_str_int(n: str, rounding_error: float = 1e-07) -> bool {
    try {
        return int(n) - float(n) < rounding_error;
    } except ValueError {
        return False;
    }
}