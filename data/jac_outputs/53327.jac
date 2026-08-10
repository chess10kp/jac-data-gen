"""Map upper-triangular matrix coordinates (i, j) to raveled list index."""
def ij_to_list_index(i: int, j: int, n: int) -> int {
    assert j >= i, "We only consider the upper triangular part...";
    index = 0;
    for k in range(i) {
        index += n - k - 1;
    }
    index + j
}