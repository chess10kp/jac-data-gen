"""
Returns the median of the elements of the iterable `x`.

If the number of elements in `x` is even, the arithmetic mean of the upper
and lower median values is returned.
"""
def median(x: list[int | float]) -> int | float {
    s = sorted(x);
    n = len(s);
    if n % 2 == 1 {
        return s[(n - 1) // 2];
    }
    m = n // 2;
    return 0.5 * (s[m - 1] + s[m]);
}