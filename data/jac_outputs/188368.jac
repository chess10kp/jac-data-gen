"""
Checks if the value is representable with the given number of bits.

Will return True if it is possible to encode the value in 'val' with the number of bits given in 'bits'.
Additionally, it can be specified if a sign has to be encoded or if the value can be rightshifted before encoding.
If encoding the value is not possible, the function will return False.
"""
def representable(val: int, bits: int, signed: bool = True, shift: int = 0) -> bool {
    if val % (1 << shift) != 0 {
        return False;
    }
    val >>= shift;
    if signed {
        return -(2 ** (bits - 1)) <= val < 2 ** (bits - 1);
    }
    return 0 <= val < 2 ** bits;
}