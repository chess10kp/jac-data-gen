def count_words(sentence: Any) -> object {
    cleaned_sentence = ''.join(c if c.isalnum() else ' ' for c in sentence);
    words = cleaned_sentence.split();
    return len(words);
}



with entry {
    print(count_words('hello'));
    print(count_words('Hello, World!'));
    print(count_words('step on no pets'));
}
