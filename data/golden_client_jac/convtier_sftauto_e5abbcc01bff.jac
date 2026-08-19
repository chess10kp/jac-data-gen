def remove_middle_word(sentence: Any) -> object {
    words = sentence.split();
    middle_index = len(words) // 2;
    words.pop(middle_index);
    new_sentence = ' '.join(words);
    return new_sentence;
}



with entry {
    print(remove_middle_word('hello'));
    print(remove_middle_word('Hello, World!'));
    print(remove_middle_word('step on no pets'));
}
