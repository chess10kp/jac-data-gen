def find_maximum(array: Any) -> object {
    max_value = array[0];
    for i in range(1, len(array)) {
        if (array[i] > max_value) {
            max_value = array[i];
        }
    }
    return max_value;
}



with entry {
    print(find_maximum('hello'));
    print(find_maximum('Racecar'));
    print(find_maximum('abcabc'));
}
