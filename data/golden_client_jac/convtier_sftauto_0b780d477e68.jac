def filter_strings_with_the(strings: Any) -> object {
    return [
        string
        for string in strings
        if ("the" not in string.lower())
    ];
}



with entry {
    print(filter_strings_with_the('hello'));
    print(filter_strings_with_the('Racecar'));
    print(filter_strings_with_the('abcabc'));
}
