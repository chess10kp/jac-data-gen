def max_subarray_sum(arr: Any) -> object {
    max_sum = arr[0];
    current_sum = arr[0];
    for i in range(1, len(arr)) {
        current_sum = max(arr[i], (current_sum + arr[i]));
        max_sum = max(max_sum, current_sum);
    }
    return max_sum;
}



with entry {
    print(max_subarray_sum('hello'));
    print(max_subarray_sum('Racecar'));
    print(max_subarray_sum('abcabc'));
}
