"""Subtract ch2 from ch1; ch2 is first adjusted to m * ch2 + c."""
def af_subtraction(ch1: float, ch2: float, m: float, c: float) -> float {
    af = m * ch2 + c;
    return ch1 - af;
}