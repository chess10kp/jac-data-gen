"""Sort values lower < pivot index < higher."""
def _partition(array: list[int], low: int, high: int, pindex: int) -> int {
    (array[low], array[pindex]) = (array[pindex], array[low]);
    i = low + 1;
    for j in range(low + 1, high) {
        if array[j] < array[low] {
            (array[i], array[j]) = (array[j], array[i]);
            i += 1;
        }
    }
    pindex = i - 1;
    (array[low], array[pindex]) = (array[pindex], array[low]);
    return pindex;
}