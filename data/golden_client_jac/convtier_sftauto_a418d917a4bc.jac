def removeExtraWhitespace(sentence: Any) -> object {
    sentence = sentence.strip();
    words = sentence.split();
    return ' '.join(words);
}



with entry {
    print(removeExtraWhitespace('hello'));
    print(removeExtraWhitespace('Racecar'));
    print(removeExtraWhitespace('abcabc'));
}
