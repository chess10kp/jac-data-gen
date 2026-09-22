"""Convert a string to a variable-length ASCII hex string."""
def str_to_hex(value: str) -> str {
    if not isinstance(value, str) {
        raise ValueError(f"Invalid value: {value}, is not a string");
    }
    return "".join(f"{ord(x):02X}" for x in value);
}