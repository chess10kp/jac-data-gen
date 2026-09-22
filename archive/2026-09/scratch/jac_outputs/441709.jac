"""Get the boolean value from location in bytearray."""
def get_bool(bytearray_: bytearray, byte_index: int, bool_index: int) -> bool {
    index_value = 1 << bool_index;
    byte_value = bytearray_[byte_index];
    return byte_value & index_value == index_value;
}