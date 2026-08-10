"""Formats an integral last key as a string, zero-padding up to 15 digits of precision.

15 digits is enough precision to handle any conceivable values we'll need to return.
"""
def FormatIntegralLastKey(value: int) -> str {
    assert value < 1000000000000000, value;
    return '%015d' % value;
}