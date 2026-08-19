def capitalize_sentence(sentence: Any) -> object {
    words = sentence.split();
    capitalized_words = [];
    for (i, word) in enumerate(words) {
        if (i == 0) {
            capitalized_words.append(word.capitalize());
        } elif (word[-1] in ['.', '!', '?']) {
            capitalized_words.append((word[:-1].capitalize() + word[-1]));
        } else {
            capitalized_words.append(word.capitalize());
        }
    }
    return ' '.join(capitalized_words);
}



with entry {
    print(capitalize_sentence('hello'));
    print(capitalize_sentence('Racecar'));
    print(capitalize_sentence('abcabc'));
}
