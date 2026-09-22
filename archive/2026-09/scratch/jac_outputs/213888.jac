"""bin n numbers into windows,
    k points per window with l overlap."""
def make_window(n: int, k: int = 1000, l: int = 100) -> list[list[int]] {
    op = [[i - l, i + k + l] for i in range(0, n, k)];
    op[0][0] = 0;
    op[-1][1] = n;
    if len(op) > 1 and op[-1][1] - op[-1][0] < k / 2 + l {
        op.pop();
        op[-1][1] = n;
    }
    return op;
}