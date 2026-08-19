def count_uppercase(string: Any) -> object {
    uppercase_chars = [
        char
        for char in string
        if char.isupper()
    ];
    return len(uppercase_chars);
}



with entry {
    print(count_uppercase('hello'));
    print(count_uppercase('Racecar'));
    print(count_uppercase('Hello, World!'));
}
