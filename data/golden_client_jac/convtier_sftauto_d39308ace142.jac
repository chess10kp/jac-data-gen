def count_words(text: Any) -> object {
    words = text.split();
    return len(words);
}



with entry {
    print(count_words('hello'));
    print(count_words('Hello, World!'));
    print(count_words('step on no pets'));
}
