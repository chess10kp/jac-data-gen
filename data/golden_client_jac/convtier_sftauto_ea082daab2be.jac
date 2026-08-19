def count_elements(arr: Any) -> object {
    count = 0;
    for element in arr {
        if isinstance(element, `list) {
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
