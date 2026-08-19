def sort_strings_by_length(strings: Any) -> object {
    return sorted(strings, key=len);
}



with entry {
    print(sort_strings_by_length('hello'));
    print(sort_strings_by_length('Racecar'));
    print(sort_strings_by_length('abcabc'));
}
