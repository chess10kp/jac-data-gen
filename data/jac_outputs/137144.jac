"""Parse an unsigned 24-bit value as a floating point and return it."""
def _read24(arr: list[int]) -> float {
    ret = 0.0;
    for b in arr {
        ret *= 256.0;
        ret += float(b & 255);
    }
    return ret;
}