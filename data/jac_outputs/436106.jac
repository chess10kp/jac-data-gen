"""
    Two's complement representation to integer.

    We assume that the number is always negative.

    1. Invert all the bits through the number
    2. Add one
    """
def twos_complement_to_int(val: Any, length: Any = 4) -> object {
    invertor = int(('1' * length), 2);
    return -((int(val, 2) ^ invertor) + 1);
}