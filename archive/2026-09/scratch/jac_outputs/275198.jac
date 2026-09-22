"""
    Computes elementwise mean across arrays.
    E.g. for input [[1, 2, 4], [5, 3, 6]] returns [3, 2.5, 5]
    """
def mean_across_arrays(arrays: list[list[float]]) -> list[float] {
    n_arrays = len(arrays);
    return [
        sum(array[i] for array in arrays) / n_arrays
        for i in range(len(arrays[0]))
    ];
}