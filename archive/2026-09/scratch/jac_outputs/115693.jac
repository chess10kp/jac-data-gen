glob POW2_18 = 1 << 18;
glob CEIL_MULT = 78913;

"""Returns ceil(log_10(2^e))"""
def CeilLog10Pow2(e: int) -> int {
    assert e >= -1650;
    assert e <= 1650;
    return (int(e) * CEIL_MULT + (POW2_18 - 1)) // POW2_18;
}