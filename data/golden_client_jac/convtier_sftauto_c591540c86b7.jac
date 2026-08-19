def unique_words(string: Any) -> object {
    words = string.split();
    unique_words_set = `set(words);
    sorted_words = sorted(unique_words_set);
    return sorted_words;
}



with entry {
    print(unique_words('hello'));
    print(unique_words('Racecar'));
    print(unique_words('abcabc'));
}
