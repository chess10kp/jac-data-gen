glob INT32_SIGN_BIT = 0x80000000;
glob INT32_VALUE_MASK = 0x7fffffff;
glob INT32_NEG_OFFSET = -0x80000000;

"""Converts a long to a signed 32-bit int."""
def i32(x: int) -> int {
    return (x & INT32_SIGN_BIT and INT32_NEG_OFFSET or 0) + int(x & INT32_VALUE_MASK);
}