"""
Unlike the book, we don't require the max value be passed in and just find
it using "max". We also just create the output array B locally instead of
passing it in.
"""
def counting_sort(A: list[int], unused_0: int = 0, unused_1: int = 0) -> list[int] {
    k = max(A) + 1;
    B = [0 for i in range(len(A))];
    C = [0 for i in range(k)];
    for j in range(len(A)) {
        C[A[j]] = C[A[j]] + 1;
    }
    for i in range(1, k) {
        C[i] = C[i] + C[i - 1];
    }
    for j in reversed(range(len(A))) {
        B[C[A[j]] - 1] = A[j];
        C[A[j]] = C[A[j]] - 1;
    }
    return B;
}