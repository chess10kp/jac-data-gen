def find_max_value(arr: Any) -> object {
    max_value = arr[0];
    for i in range(1, len(arr)) {
        if (arr[i] > max_value) {
            max_value = arr[i];
        }
    }
    return max_value;
}



with entry {
    print(find_max_value('hello'));
    print(find_max_value('Racecar'));
    print(find_max_value('abcabc'));
}
