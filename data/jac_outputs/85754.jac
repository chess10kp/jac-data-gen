"""
    Returns bytearray of at least size bytes equivalent of integer n that is
    left zero padded to size bytes. For n positive, if the bytearray
    equivalent of n is longer than size  and strict is False the bytearray
    is extended to the length needed to fully represent n. Otherwise if strict
    is True or n is negative it is truncated to the least significant size bytes.

    Big endian is the default.
    If reverse is true then it reverses the order of the bytes in the resultant
    bytearray for little endian with right zero padding.
    """
def bytify(
    n: int = 0, size: int = 1, reverse: bool = False, strict: bool = False
) -> bytearray {
    if n < 0 or strict {
        n = n & ((2 ** (size * 8)) - 1);
    }
    b = bytearray();
    count = 0;
    while n {
        b.insert(0, (n & 255));
        count += 1;
        n >>= 8;
    }
    if count < size {
        b = bytearray(([0] * (size - count))) + b;
    }
    if reverse {
        b.reverse();
    }
    return b;
}