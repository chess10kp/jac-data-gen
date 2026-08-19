def sortString(words: Any) -> object {
    sorted_words = [];
    for word in words {
        sorted_word = ''.join(sorted(word));
        sorted_words.append(sorted_word);
    }
    return sorted(sorted_words);
}



with entry {
    print(sortString('hello'));
    print(sortString('Racecar'));
    print(sortString('abcabc'));
}
