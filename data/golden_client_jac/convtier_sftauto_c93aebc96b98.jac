def flatten_and_sum(arr: Any) -> object {
    flat_arr = [num for sublist in arr for num in sublist];
    return sum(flat_arr);
}



with entry {
    print(flatten_and_sum([]));
}
