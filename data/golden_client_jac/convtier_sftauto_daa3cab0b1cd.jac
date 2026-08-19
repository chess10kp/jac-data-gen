def count_words(string: Any) -> object {
    string = string.strip();
    words = string.split();
    word_count = len(words);
    return word_count;
}



with entry {
    print(count_words('hello'));
    print(count_words('Hello, World!'));
    print(count_words('step on no pets'));
}
