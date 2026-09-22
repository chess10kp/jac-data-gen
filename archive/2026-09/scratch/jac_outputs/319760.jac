"""Convert pair of coordinates of a symmetric square array into consecutive index of
    flattened upper triangle. This is slimmed down so it won't throw errors like if i>n or
    j>n or if they're negative. Only checking for if the returned index is negative which
    could be problematic with wrapped indices.
    """
def sub_to_ind(n: int, i: int, j: int) -> int {
    if i < j {
        k = 0;
        for l in range(1, i + 2) {
            k += n - l;
        }
        assert k >= 0;
        return k - n + j;
    } elif i > j {
        k = 0;
        for l in range(1, j + 2) {
            k += n - l;
        }
        assert k >= 0;
        return k - n + i;
    } else {
        raise Exception("Indices cannot be the same.");
    }
}