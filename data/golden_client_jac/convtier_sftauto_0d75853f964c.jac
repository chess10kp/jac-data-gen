def max_sum_subarray(arr: Any) -> object {
    max_sum = float('-inf');
    curr_sum = 0;
    for num in arr {
        curr_sum += num;
        if (curr_sum > max_sum) {
            max_sum = curr_sum;
        }
        if (curr_sum < 0) {
            curr_sum = 0;
        }
    }
    return max_sum;
}



with entry {
    print(max_sum_subarray([]));
}
