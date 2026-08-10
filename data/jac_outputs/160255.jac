"""Selection partition."""
def partition(array: list[int], pivot: int) -> int {
    i = -1;
    j = 0;
    while j < len(array) - 1 {
        if array[j] == pivot {
            (array[-1], array[j]) = (array[j], array[-1]);
            continue;
        } elif array[j] < pivot {
            i += 1;
            (array[i], array[j]) = (array[j], array[i]);
        }
        j += 1;
    }
    (array[-1], array[i + 1]) = (array[i + 1], array[-1]);
    return i + 1;
}