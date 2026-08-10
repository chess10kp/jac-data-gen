"""Returns the integer square root of n; i.e. r=isqrt(n) is the greatest
integer such that r**2<=n."""
def isqrt(n: int) -> int {
    x = n;
    y = (x + 1) // 2;
    while y < x {
        x = y;
        y = (x + n // x) // 2;
    }
    return x;
}