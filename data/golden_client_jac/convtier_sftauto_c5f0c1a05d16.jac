def repeat_elements(alphabet: Any) -> object {
    repeated_elements = [];
    for element in alphabet {
        length = len(element);
        for _ in range(length) {
            repeated_elements.append(element);
        }
    }
    return repeated_elements;
}



with entry {
    print(repeat_elements('hello'));
    print(repeat_elements('Racecar'));
    print(repeat_elements('abcabc'));
}
