"""Preserves byte strings, converts Unicode into UTF-8.

    Args:
        array (bytearray or str) : input array of bytes or chars

    Returns:
        UTF-8 encoded bytearray
    """
def utf8(array: bytes | str) -> bytes {
    if isinstance(array, bytes) {
        return array;
    }
    return array.encode("utf-8");
}