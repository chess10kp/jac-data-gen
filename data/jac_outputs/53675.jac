"""Split the A array into bins of size N."""
def split_to_bins(A: list[int], S: int = 4) -> list[list[int]] {
    m = len(A) // S;
    n = len(A) % S;
    return [A[i * S:(i + 1) * S] for i in range(m + bool(n))];
}