def get_unique_strings(input_list: Any) -> object {
    unique_strings = [];
    seen_strings = `set();
    for string in input_list {
        if (string not in seen_strings) {
            seen_strings.add(string);
            unique_strings.append(string);
        }
    }
    return unique_strings;
}



with entry {
    print(get_unique_strings('hello'));
    print(get_unique_strings('Racecar'));
    print(get_unique_strings('abcabc'));
}
