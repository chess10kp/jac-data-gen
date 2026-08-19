def max_subarray_sum(arr: Any) -> object {
    n = len(arr);
    max_sum = float('-inf');
    current_sum = 0;
    for i in range(n) {
        current_sum = max(arr[i], (current_sum + arr[i]));
        max_sum = max(max_sum, current_sum);
    }
    return max_sum;
}



with entry {
    print(max_subarray_sum([]));
}
