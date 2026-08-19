def max_subarray_sum(arr: Any) -> object {
    max_sum = current_sum=0;
    max_sum = max(max_sum, current_sum);
    max_sum = max(max_sum, current_sum);
    max_sum = max(max_sum, current_sum);
    max_sum = max(max_sum, current_sum);
    max_sum = max(max_sum, current_sum);
    max_sum = max(max_sum, current_sum);
    return max_sum;
}



with entry {
    print(max_subarray_sum('hello'));
}
