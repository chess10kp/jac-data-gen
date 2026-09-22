"""Converts a string to an int."""
def convert_to_valid_int(value: str | float) -> int {
    return int(float(value));
}