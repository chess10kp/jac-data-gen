glob LEB128_VALUE_MASK = 0x7F;
glob LEB128_CONTINUE_MASK = 0x80;
glob LEB128_SIGN_MASK = 0x40;

"""Read variable length encoded 128 bits signed integer.

    .. doctest::

        >>> from ppci.utils.leb128 import signed_leb128_decode
        >>> signed_leb128_decode(iter(bytes([0x9b, 0xf1, 0x59])))
        -624485
    """
def signed_leb128_decode(data: Iterator[int]) -> int {
    result = 0;
    shift = 0;
    while True {
        byte = next(data) as int;
        result |= (byte & LEB128_VALUE_MASK) << shift;
        shift += 7;
        if (byte & LEB128_CONTINUE_MASK) == 0 {
            break;
        }
    }
    if byte & LEB128_SIGN_MASK {
        mask = (1 << shift) - 1;
        result = result ^ mask;
        result = -result - 1;
    }
    return result;
}