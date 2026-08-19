def calculate_median(arr: Any) -> object {
    n = len(arr);
    middle_index = (n - 1) // 2;
    median = arr[middle_index];
    return median;
}



with entry {
    print(calculate_median('hello'));
    print(calculate_median('Racecar'));
    print(calculate_median('abcabc'));
}
