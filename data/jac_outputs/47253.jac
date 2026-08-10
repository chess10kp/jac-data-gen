"""Returns the value of a single bit in a number."""
def bit_read(data: bytearray, position: int) -> bool {
    byte_pos = int(position // 8);
    bit_pos = int(position % 8);
    return bool((data[byte_pos] & (1 << bit_pos)) >> bit_pos);
}