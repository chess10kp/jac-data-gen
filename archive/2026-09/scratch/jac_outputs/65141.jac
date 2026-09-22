"""Returns 10**-x, or `fallback` if it doesn't meet the threshold."""
def min_ten_neg(x: int | float, thresh: int | float, fallback: int | float) -> int | float {
    x = 10 ** -x;
    return x if x and x > thresh else fallback;
}