def find_maximum(arr: Any) -> object {
    if (len(arr) == 0) {
        return None;
    }
    max_num = arr[0];
    for i in range(1, len(arr)) {
        if (arr[i] > max_num) {
            max_num = arr[i];
        }
    }
    return max_num;
}



with entry {
    print(find_maximum('hello'));
    print(find_maximum('Racecar'));
    print(find_maximum('abcabc'));
}
