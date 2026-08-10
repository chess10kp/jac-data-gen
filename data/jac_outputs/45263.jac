"""Utility to convert rounded floats to int."""
def it(item: int | float | str) -> int | float | str {
    try {
        is_equal = int(item) == float(item);
    } except ValueError {
        return item;
    }
    return int(item) if is_equal else float(item);
}