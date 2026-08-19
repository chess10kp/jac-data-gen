def find_max_value(array: Any) -> object {
    max_value = array[0];
    for i in range(1, len(array)) {
        if (array[i] > max_value) {
            max_value = array[i];
        }
    }
    return max_value;
}



with entry {
    print(find_max_value('hello'));
    print(find_max_value('Racecar'));
    print(find_max_value('abcabc'));
}
