"""Memory usage of parity check matrix in vector space elements."""
def _mem_matrix(n: int, k: int, r: int) -> int {
    return n - k + (2 ** r);
}