def count_unique_characters(input: Any) -> object {
    unique_chars = `set();
    for char in input {
        char = char.lower();
        unique_chars.add(char);
    }
    return len(unique_chars);
}



with entry {
    print(count_unique_characters('hello'));
    print(count_unique_characters('abcabc'));
    print(count_unique_characters('Hello, World!'));
}
