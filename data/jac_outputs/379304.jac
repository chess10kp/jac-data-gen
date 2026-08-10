"""
    Count number of bits needed to store a (positive) integer number.

    >>> countBits(0)
    1
    >>> countBits(1000)
    10
    >>> countBits(44100)
    16
    >>> countBits(18446744073709551615)
    64
    """
def countBits(value: int) -> int {
    assert 0 <= value;
    count = 1;
    bits = 1;
    while (1 << bits) <= value {
        count += bits;
        value >>= bits;
        bits <<= 1;
    }
    while 2 <= value {
        if bits != 1 {
            bits >>= 1;
        } else {
            bits -= 1;
        }
        while (1 << bits) <= value {
            count += bits;
            value >>= bits;
        }
    }
    return count;
}