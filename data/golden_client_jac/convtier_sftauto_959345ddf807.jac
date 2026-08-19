def word_length_dict(words: Any) -> object {
    length_dict = {};
    for word in words {
        length_dict[word] = len(word);
    }
    return length_dict;
}



with entry {
    print(word_length_dict('hello'));
    print(word_length_dict('Racecar'));
    print(word_length_dict('abcabc'));
}
