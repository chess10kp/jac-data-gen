def sort_and_remove_duplicates(strings: Any) -> object {
    strings = `list(`set(strings));
    strings.sort();
    return strings;
}



with entry {
    print(sort_and_remove_duplicates('hello'));
    print(sort_and_remove_duplicates('Racecar'));
    print(sort_and_remove_duplicates('abcabc'));
}
