def flatten_and_sort(arr: Any) -> object {
    flattened = [num for sublist in arr for num in sublist];
    unique_nums = `list(`set(flattened));
    sorted_nums = sorted(unique_nums);
    return sorted_nums;
}



with entry {
    print(flatten_and_sort('hello'));
    print(flatten_and_sort('Racecar'));
    print(flatten_and_sort('abcabc'));
}
