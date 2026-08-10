"""Converts a string argument to a byte string"""
def str_to_bytes(value: str | bytes, encoding: str = "utf8") -> bytes {
    if isinstance(value, bytes) {
        return value;
    }
    if not isinstance(value, str) {
        raise TypeError(('%r is not a string' % value));
    }
    return value.encode(encoding);
}