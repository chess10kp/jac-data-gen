""" merge sort works by recursively spliting a list down to a
    binary comparison and then sorting smaller values to the left
    """
def mergesort(_list: list[int]) -> list[int] {
    if not isinstance(_list, list) {
        raise TypeError;
    }
    if len(_list) > 1 {
        half = len(_list) // 2;
        left_half = _list[:half];
        right_half = _list[half:];
        mergesort(left_half);
        mergesort(right_half);
        i = 0;
        j = 0;
        k = 0;
        while i < len(left_half) and j < len(right_half) {
            if left_half[i] < right_half[j] {
                _list[k] = left_half[i];
                i += 1;
            } else {
                _list[k] = right_half[j];
                j += 1;
            }
            k += 1;
        }
        while i < len(left_half) {
            _list[k] = left_half[i];
            i += 1;
            k += 1;
        }
        while j < len(right_half) {
            _list[k] = right_half[j];
            j += 1;
            k += 1;
        }
    }
    return _list;
}