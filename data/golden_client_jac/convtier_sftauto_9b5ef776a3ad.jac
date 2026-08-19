def convert_to_dictionary(strings: Any) -> object {
    dictionary = {};
    for string in strings {
        dictionary[string] = len(string);
    }
    return dictionary;
}



with entry {
    print(convert_to_dictionary('hello'));
    print(convert_to_dictionary('Racecar'));
    print(convert_to_dictionary('abcabc'));
}
