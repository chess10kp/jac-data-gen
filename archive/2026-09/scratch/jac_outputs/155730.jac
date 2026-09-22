"""Returns the number of terms specifically at order n (not counting the ones below n)."""
def terms_of_order_n(n: int, p: int) -> int {
    if n == 0 {
        return 1;
    }
    if p == 1 {
        return 1;
    }
    w = 0;
    for i in range(n + 1) {
        w += terms_of_order_n(i, p - 1);
    }
    return w;
}