"""Hex representation as network order with size of ``octets``."""
def int_to_hex(value: int, octets: int = 2) -> str {
    return '%%0%dx' % (octets * 2) % value;
}