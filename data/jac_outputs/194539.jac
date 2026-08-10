glob U16_SIGN_BIT = 0x8000;
glob U16_MOD = 0x10000;

"""Reinterpret the unsigned 16-bit integer `n` as a signed integer."""
def from_u16(n: int) -> int {
    if n >= U16_SIGN_BIT {
        return -(U16_MOD - n);
    }
    return n;
}