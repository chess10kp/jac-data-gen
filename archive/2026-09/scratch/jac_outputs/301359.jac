"""Shift positive left, or negative right.  Same as n * 2**nbits"""
def shift_leftward(n: Any, nbits: Any) -> object {
    if (nbits < 0) {
        return (n >> -nbits);
    } else {
        return (n << nbits);
    }
}