"""Binary Search takes array and value to search."""
def binary_search(arr: list[int], value: int) -> int {
    count = len(arr);
    midpoint = count // 2;
    start_index = 0;
    end_index = count - 1;
    while value != arr[start_index + midpoint] and count > 1 {
        if value > arr[midpoint + start_index] {
            start_index = midpoint;
            count = count - midpoint;
            midpoint = count // 2;
        } else {
            end_index = end_index - midpoint;
            count = count - midpoint;
            midpoint = count // 2;
        }
    }
    if value == arr[midpoint + start_index] {
        return midpoint + start_index;
    }
    return -1;
}