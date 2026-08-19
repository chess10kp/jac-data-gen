def count_lowercase_letters(string: Any) -> object {
    count = 0;
    for char in string {
        if ('a' <= char <= 'z') {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_lowercase_letters('hello'));
    print(count_lowercase_letters('Racecar'));
    print(count_lowercase_letters('Hello, World!'));
}
