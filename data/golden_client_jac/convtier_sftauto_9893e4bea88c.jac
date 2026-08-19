def count_unique_characters(string: Any) -> object {
    unique_chars = `set(string);
    return len(unique_chars);
}



with entry {
    print(count_unique_characters('hello'));
    print(count_unique_characters('Racecar'));
    print(count_unique_characters('abcabc'));
}
