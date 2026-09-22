"""
We can either take or leave the current number depending on previous max number
"""
def max_sum_naive(arr: list[int], length: int, index: int, prev_max: int) -> int {
    if index >= length {
        return 0;
    }
    cur_max = 0;
    if arr[index] > prev_max {
        cur_max = arr[index] + max_sum_naive(arr, length, index + 1, arr[index]);
    }
    return max(cur_max, max_sum_naive(arr, length, index + 1, prev_max));
}