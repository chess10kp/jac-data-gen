def count_unique_strings(list_elements: Any) -> object {
    unique_strings = `set();
    for element in list_elements {
        if (isinstance(element, str) and (element not in unique_strings)) {
            unique_strings.add(element);
        }
    }
    return len(unique_strings);
}



with entry {
    print(count_unique_strings('hello'));
    print(count_unique_strings('Racecar'));
    print(count_unique_strings('abcabc'));
}
