def find_max(array: Any) -> object {
    max_number = array[0];
    for i in range(1, len(array)) {
        if (array[i] > max_number) {
            max_number = array[i];
        }
    }
    return max_number;
}



with entry {
    print(find_max('hello'));
    print(find_max('Racecar'));
    print(find_max('abcabc'));
}
