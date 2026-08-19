def count_unique_chars(string: Any) -> object {
    unique_chars = `set(string);
    return len(unique_chars);
}



with entry {
    print(count_unique_chars('hello'));
    print(count_unique_chars('Racecar'));
    print(count_unique_chars('abcabc'));
}
