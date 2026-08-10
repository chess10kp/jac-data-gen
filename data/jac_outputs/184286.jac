"""Return YES if A and B can be permuted so A'[i] + B'[i] >= k for all i."""
def two_arrays(k: int, A: list[int], B: list[int]) -> str {
    A.sort();
    B.sort(reverse=True);
    for (a, b) in zip(A, B) {
        if a + b < k {
            return "NO";
        }
    }
    return "YES";
}