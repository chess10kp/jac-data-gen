def capitalize_sentence(sentence: Any) -> object {
    words = sentence.split();
    capitalized_words = [word.capitalize() for word in words];
    capitalized_sentence = ' '.join(capitalized_words);
    return capitalized_sentence;
}



with entry {
    print(capitalize_sentence('hello'));
    print(capitalize_sentence('Racecar'));
    print(capitalize_sentence('abcabc'));
}
