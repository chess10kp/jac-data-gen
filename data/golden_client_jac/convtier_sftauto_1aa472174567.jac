def find_first_max_index(arr: Any) -> object {
    if (len(arr) == 0) {
        return -1;
    }
    max_val = arr[0];
    max_index = 0;
    for i in range(1, len(arr)) {
        if (arr[i] > max_val) {
            max_val = arr[i];
            max_index = i;
        } elif (arr[i] == max_val) {
            if (i < max_index) {
                max_index = i;
            }
        }
    }
    return max_index;
}



with entry {
    print(find_first_max_index('hello'));
    print(find_first_max_index('Racecar'));
    print(find_first_max_index('abcabc'));
}
