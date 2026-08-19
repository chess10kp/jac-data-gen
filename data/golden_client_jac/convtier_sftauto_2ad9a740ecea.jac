def count_unique_alphabets(string: Any) -> object {
    string = string.lower();
    unique_alphabets = `set();
    for char in string {
        if char.isalpha() {
            unique_alphabets.add(char.lower());
        }
    }
    return len(unique_alphabets);
}



with entry {
    print(count_unique_alphabets('hello'));
    print(count_unique_alphabets('abcabc'));
    print(count_unique_alphabets('Hello, World!'));
}
