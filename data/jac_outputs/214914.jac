"""Returns a hex string of an int."""
def int_to_hex_string(value: int, length: int = 64) -> str {
    hex_string = str(hex(value))[2:];
    return "0" * (length - len(hex_string)) + hex_string;
}