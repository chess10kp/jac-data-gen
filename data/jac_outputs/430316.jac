"""Sort a list in ascending order. The original list is mutated and
    returned. The sort is stable.

    Design idea: Iterate over the list. After i iterations, the first i elements
    of the list should be sorted. Insert the i+1'th element in the appropriate
    spot in the sorted sublist. Note that this idea differs from selection sort
    in that the first i elements are sorted, but not necessarily in their final
    order.

    Complexity: O(n^2) time, O(1) space. Stable and in-place.
    """
def insertion_sort(lst: list[int]) -> list[int] {
    for i in range(1, len(lst)) {
        v = lst[i];
        j = i - 1;
        while j >= 0 and lst[j] > v {
            lst[j + 1] = lst[j];
            j -= 1;
        }
        lst[j + 1] = v;
    }
    return lst;
}