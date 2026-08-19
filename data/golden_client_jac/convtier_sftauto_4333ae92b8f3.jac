def max_subarray_sum(arr: Any) -> object {
    max_sum = [];
    for row in arr {
        max_sum.append(max(0, max(row)));
    }
    return max_sum;
}



with entry {
    print(max_subarray_sum([]));
}
