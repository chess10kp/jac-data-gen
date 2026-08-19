def count_elements(array: Any) -> object {
    count = 0;
    for element in array {
        if (`type(element) == `list) {
            count += count_elements(element);
        } else {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_elements('hello'));
    print(count_elements('Racecar'));
    print(count_elements('abcabc'));
}
