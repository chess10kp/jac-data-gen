"""Convert index from flattened upper triangular matrix to pair subindex.

    Parameters
    ----------
    n : int
        Dimension size of square array.
    ix : int
        Index to convert.

    Returns
    -------
    subix : tuple
        (i,j)
    """
def ind_to_sub(n: int, ix: int) -> tuple[int, int] | None {
    k = 0;
    for i in range(n - 1) {
        for j in range(i + 1, n) {
            if k == ix {
                return (i, j);
            }
            k += 1;
        }
    }
}