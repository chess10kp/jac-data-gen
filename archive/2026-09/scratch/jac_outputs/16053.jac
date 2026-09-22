"""Convert integer to byte array in big endian format."""
def int_to_bytes(number: int) -> bytes {
    return number.to_bytes((number.bit_length() + 7) // 8, byteorder='big');
}