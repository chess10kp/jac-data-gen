"""Binary search on a sorted array.

    Arguments:
    key - filter for objects in the array
    start - 0-indexed starting marker on the array to search
    end - exclusive ending marker on the array to search
    """
def binary_search(
    array: list[int] | None,
    query: int,
    key: Callable[[int], int] = lambda (a: int) { a; },
    start: int = 0,
    end: int = -1
) -> int | None {
    if array is None or len(array) == 0 {
        return None;
    }
    if end == -1 {
        end = len(array);
    } elif start >= end {
        return None;
    }
    mid = int(start + (end - start) / 2);
    compare_to = key(array[mid]);
    if query < compare_to {
        return binary_search(array, query, key, start, mid);
    } elif query > compare_to {
        return binary_search(array, query, key, mid + 1, end);
    } else {
        return array[mid];
    }
}