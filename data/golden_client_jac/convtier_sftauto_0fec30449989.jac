def get_unique_elements(lst: Any) -> object {
    unique_elements = [];
    seen = `set();
    for element in lst {
        if (element not in seen) {
            seen.add(element);
            unique_elements.append(element);
        }
    }
    return unique_elements;
}



with entry {
    print(get_unique_elements('hello'));
    print(get_unique_elements('Racecar'));
    print(get_unique_elements('abcabc'));
}
