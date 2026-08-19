def remove_duplicates_and_sort(arr: Any) -> object {
    unique_arr = `list(`set(arr));
    n = len(unique_arr);
    for i in range((n - 1)) {
        for j in range(0, (n - i - 1)) {
            if (unique_arr[j] < unique_arr[(j + 1)]) {
                (unique_arr[j], unique_arr[(j + 1)]) = (
                    unique_arr[(j + 1)],
                    unique_arr[j]
                );
            }
        }
    }
    return unique_arr;
}



with entry {
    print(remove_duplicates_and_sort('hello'));
    print(remove_duplicates_and_sort('Racecar'));
    print(remove_duplicates_and_sort('abcabc'));
}
