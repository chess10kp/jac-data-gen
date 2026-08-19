def modify_sentence(sentence: Any) -> object {
    words = sentence.split();
    reversed_words = [];
    for word in reversed(words) {
        if (
            (len(word) >= 3)
            and not `any((char.lower() in ['a', 'e']) for char in word)
            and word[0].isalpha()
        ) {
            reversed_words.append(word.capitalize());
        }
    }
    reversed_sentence = ' '.join(reversed_words);
    return reversed_sentence;
}



with entry {
    print(modify_sentence('hello'));
    print(modify_sentence('Hello, World!'));
}
