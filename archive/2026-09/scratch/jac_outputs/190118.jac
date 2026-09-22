glob POPCOUNT_MASK_55 = 0x5555555555555555;
glob POPCOUNT_MASK_33 = 0x3333333333333333;
glob POPCOUNT_MASK_0F = 0x0F0F0F0F0F0F0F0F;
glob POPCOUNT_MASK_7F = 0x0000007F;

"""Popcount."""
def popcount(n: int) -> int {
    n -= (n >> 1) & POPCOUNT_MASK_55;
    n = (n & POPCOUNT_MASK_33) + ((n >> 2) & POPCOUNT_MASK_33);
    n = (n + (n >> 4)) & POPCOUNT_MASK_0F;
    n = n + (n >> 8);
    n = n + (n >> 16);
    n = n + (n >> 32);
    return n & POPCOUNT_MASK_7F;
}