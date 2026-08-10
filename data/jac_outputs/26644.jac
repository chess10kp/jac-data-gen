"""Integer value of the byte stream."""
def bytes_to_int(byte_string: bytes) -> int {
    return int.from_bytes(byte_string, "big");
}