"""Convert number to 8-digit zero-padded hex string."""
def long_hex(number: int) -> str {
    value_hex = hex(number);
    if len(value_hex) < 10 {
        value_hex = value_hex[0:2] + '0' * (10 - len(value_hex)) + value_hex[2:];
    }
    return value_hex;
}