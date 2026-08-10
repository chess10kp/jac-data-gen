"""bisection search (left)"""
def bisect_left(a: list[int], x: int, lo: int = 0, hi: int | None = None) -> int {
    if hi is None {
        hi = len(a);
    }
    while lo < hi {
        mid = (lo + hi) // 2;
        if a[mid] < x {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return lo;
}