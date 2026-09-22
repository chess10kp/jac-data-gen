"""
Reduces an NxN matrix over finite field Z/pZ.
"""
def reduce_matrix(M: list[list[int]], p: int, is_noise: bool = False) -> list[list[int]] {
    for (i, row) in enumerate(M) {
        for (j, element) in enumerate(row) {
            if is_noise and element < 0 and abs(element) < p {
                continue;
            }
            M[i][j] = element % p;
        }
    }
    return M;
}