"""Return neighboring indices for a cell in an m x n matrix."""
def neighbors(i: int, j: int, m: int, n: int) -> list[tuple[int, int]] {
    inbrs = [-1, 0, 1];
    if i == 0 {
        inbrs = [0, 1];
    }
    if i == m - 1 {
        inbrs = [-1, 0];
    }
    jnbrs = [-1, 0, 1];
    if j == 0 {
        jnbrs = [0, 1];
    }
    if j == n - 1 {
        jnbrs = [-1, 0];
    }
    return [
        (i + delta_i, j + delta_j)
        for delta_i in inbrs
        for delta_j in jnbrs
        if not (delta_i == delta_j == 0)
    ];
}