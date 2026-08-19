def custom_sort(strings: Any) -> object {
    def sort_key(string: Any) -> object {
        normalized_string = string.lower().rstrip();
        return (normalized_string, string);
    }
    sorted_strings = sorted(strings, key=sort_key);
    return sorted_strings;
}



with entry {
    print(custom_sort('hello'));
    print(custom_sort('Racecar'));
    print(custom_sort('abcabc'));
}
