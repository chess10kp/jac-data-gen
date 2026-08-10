"""Stage cost function for $\delta_N^i$ and $\delta_M^k$"""
def g(i: int, k: int) -> float {
    B = [0, 1];
    A = [
        14, 8, 14, 2, 17, 8, 1, 13, 3, 14, 11, 14, 19, 2, 19, 11,
        15, 10, 16, 6, 4, 8, 19, 12, 3, 14, 17, 8, 16, 11, 12, 11
    ];
    A[i - 1] + B[k - 1]
}