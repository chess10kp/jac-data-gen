glob BYTE_MASK = 0xFF;

"""Converts an int to an array of 2 bytes (little endian)."""
def convert_uint16_to_array(value: int) -> list[int] {
    byte0 = value & BYTE_MASK;
    byte1 = (value >> 8) & BYTE_MASK;
    return [byte0, byte1];
}