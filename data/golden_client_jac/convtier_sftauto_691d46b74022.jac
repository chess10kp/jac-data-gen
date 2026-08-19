def find_min(arr: Any) -> object {
    min_val = arr[0];
    for i in range(1, len(arr)) {
        if (arr[i] < min_val) {
            min_val = arr[i];
        }
    }
    return min_val;
}



with entry {
    print(find_min('hello'));
    print(find_min('Racecar'));
    print(find_min('abcabc'));
}
