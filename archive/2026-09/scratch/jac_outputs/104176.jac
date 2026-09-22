"""Compute needed ribbon for one present.

Arguments l, w, and h are expected to be sorted for a correct result.
"""
def one_ribbon(l: int | float, w: int | float, h: int | float) -> int | float {
    return 2 * (l + w) + l * w * h;
}