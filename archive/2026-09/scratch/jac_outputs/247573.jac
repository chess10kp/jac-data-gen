"""Custom rounding for histogram."""
def myround(x: float | int, base: int = 5) -> int {
    ratio = float(x) / float(base);
    return int(float(base) * float(round(ratio)));
}