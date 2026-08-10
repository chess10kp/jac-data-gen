"""
:type x: int
:rtype: int
"""
def my_sqrt(x: int) -> int | None {
    if x <= 1 {
        return x;
    }
    (l, r) = (0, x);
    while l + 1 < r {
        mid = l + (r - l) // 2;
        if mid * mid <= x < (mid + 1) * (mid + 1) {
            return mid;
        } elif mid * mid > x {
            r = mid;
        } else {
            l = mid;
        }
    }
}