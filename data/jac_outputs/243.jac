"""
    Swap the endianness of a number
    """
def _swap_endian(val: Any, length: Any) -> object {
    if (length <= 8) {
        return val;
    }
    if (length <= 16) {
        return (((val & 65280) >> 8) | ((val & 255) << 8));
    }
    if (length <= 32) {
        return (
            ((val & 4278190080) >> 24)
            | ((val & 16711680) >> 8)
            | ((val & 65280) << 8)
            | ((val & 255) << 24)
        );
    }
    raise Exception(('Cannot swap endianness for length ' + length));
}