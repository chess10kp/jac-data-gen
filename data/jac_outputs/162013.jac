"""Efficiently convert an integer to a serializable byte string."""
def serialize_int(x: int) -> bytes {
    byte_size = (x.bit_length() + 8) // 8;
    return x.to_bytes(byte_size, 'big');
}