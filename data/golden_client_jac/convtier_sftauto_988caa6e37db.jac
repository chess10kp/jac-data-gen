def count_words(string: Any) -> object {
    count = 0;
    words = string.lower().split();
    for word in words {
        if (word not in ['test', 'testing', 'tested', 'tests']) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_words('hello'));
    print(count_words('Hello, World!'));
    print(count_words('step on no pets'));
}
