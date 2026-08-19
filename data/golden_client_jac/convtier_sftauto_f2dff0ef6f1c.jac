def invert_words(string: Any) -> object {
    words = string.split(" ");
    inverted_words = [];
    for word in words {
        inverted_word = word[::-1];
        inverted_words.append(inverted_word);
    }
    inverted_string = " ".join(inverted_words);
    return inverted_string;
}



with entry {
    print(invert_words('hello'));
    print(invert_words('Racecar'));
    print(invert_words('abcabc'));
}
