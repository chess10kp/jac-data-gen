def count_unique_alphabets(string: Any) -> object {
    unique_alphabets = `set();
    string = string.lower();
    for char in string {
        if char.isalpha() {
            unique_alphabets.add(char);
        }
    }
    return len(unique_alphabets);
}



with entry {
    print(count_unique_alphabets('hello'));
    print(count_unique_alphabets('abcabc'));
    print(count_unique_alphabets('Hello, World!'));
}
