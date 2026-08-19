def capitalize_sentence(sentence: Any) -> object {
    words = sentence.split();
    capitalized_words = [];
    for word in words {
        if (word.lower() not in ['and', 'the']) {
            word = word.rstrip(",.!?;:'");
            word = word[0].upper() + word[1:];
        }
        capitalized_words.append(word);
    }
    return ' '.join(capitalized_words);
}



with entry {
    print(capitalize_sentence('hello'));
    print(capitalize_sentence('Racecar'));
    print(capitalize_sentence('abcabc'));
}
