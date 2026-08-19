def find_max(arr: Any) -> object {
    if (len(arr) == 0) {
        return -1;
    }
    max_num = arr[0];
    max_index = 0;
    for i in range(1, len(arr)) {
        if (arr[i] > max_num) {
            max_num = arr[i];
            max_index = i;
        }
    }
    return max_index;
}



with entry {
    print(find_max('hello'));
    print(find_max('Racecar'));
    print(find_max('abcabc'));
}
