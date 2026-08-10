""" Linear method
        Initialize values of min and max as minimum and maximum of the first two elements
        respectively. Starting from 3rd, compare each element with max and min, and
        change max and min accordingly
    """
def getminmax_linear_search(arr: list[int]) -> tuple[int | None, int | None] {
    if len(arr) == 0 {
        return (None, None);
    }
    if len(arr) == 1 {
        return (arr[0], arr[0]);
    }
    if arr[0] > arr[1] {
        max_num = arr[0];
        min_num = arr[1];
    } else {
        max_num = arr[1];
        min_num = arr[0];
    }
    for idx in range(2, len(arr)) {
        if min_num > arr[idx] {
            min_num = arr[idx];
        }
        if max_num < arr[idx] {
            max_num = arr[idx];
        }
    }
    return (min_num, max_num);
}