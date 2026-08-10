""" Convert an integer to bigendian byte string.
    """
def int_2_bigend(p_int: int, p_len: int) -> bytes {
    return p_int.to_bytes(p_len, byteorder='big');
}