"""Remove trailing zeroes in `t`."""
def rstrip_tuple(t: tuple[int, ...]) -> tuple[int, ...] {
    if not t or t[-1] {
        return t;
    }
    right = len(t) - 1;
    while right > 0 and t[right - 1] == 0 {
        right -= 1;
    }
    return t[0:right];
}