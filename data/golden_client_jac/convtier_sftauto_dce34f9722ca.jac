def max_subarray_sum(arr: Any) -> object {
    max_so_far = float('-inf');
    max_ending_here = 0;
    for num in arr {
        max_ending_here += num;
        if (max_ending_here < 0) {
            max_ending_here = 0;
        } elif (max_so_far < max_ending_here) {
            max_so_far = max_ending_here;
        }
    }
    return max_so_far;
}



with entry {
    print(max_subarray_sum([]));
}
