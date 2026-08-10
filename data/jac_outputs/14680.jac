"""Changes an unsigned integer into bytes."""
def int_to_bytes(x: Any) -> object {
    return x.to_bytes(((x.bit_length() + 7) // 8), 'big');
}