def extract_words(sentence: Any) -> object {
    words = sentence.split();
    result = [
        word
        for word in words
        if (len(word) >= 5)
    ];
    return result;
}



with entry {
    print(extract_words('hello'));
    print(extract_words('Racecar'));
    print(extract_words('abcabc'));
}
