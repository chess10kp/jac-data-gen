def remove_duplicates(input_array: Any) -> object {
    unique_elements = [];
    seen_elements = `set();
    for element in input_array {
        if (element not in seen_elements) {
            unique_elements.append(element);
            seen_elements.add(element);
        }
    }
    return unique_elements;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
