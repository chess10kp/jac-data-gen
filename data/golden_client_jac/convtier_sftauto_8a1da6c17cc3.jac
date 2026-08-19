def find_missing_number(arr: Any) -> object {
    n = len(arr) + 1;
    total_sum = (n * (n + 1)) // 2;
    arr_sum = sum(arr);
    missing_number = total_sum - arr_sum;
    return missing_number;
}



with entry {
    print(find_missing_number([4, 2, 1]));
    print(find_missing_number([5, 5, 5]));
    print(find_missing_number([10, 20, 30]));
}
