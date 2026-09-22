"""Converts the given value (0-255) into its hexadecimal representation"""
def toFloat(val: str) -> float {
    hex_digits = "0123456789abcdef";
    return float(hex_digits.find(val[0]) * 16 + hex_digits.find(val[1]));
}