def count_distinct_lowercase_letters(string: Any) -> object {
    distinct_letters = `set();
    for char in string {
        if char.islower() {
            distinct_letters.add(char);
        }
    }
    return len(distinct_letters);
}



with entry {
    print(count_distinct_lowercase_letters('hello'));
    print(count_distinct_lowercase_letters('abcabc'));
    print(count_distinct_lowercase_letters('Hello, World!'));
}
