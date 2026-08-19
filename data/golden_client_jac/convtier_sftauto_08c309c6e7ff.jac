def split_string(str: Any) -> object {
    words = str.split();
    unique_words = `set(words);
    sorted_words = sorted(unique_words, key=len);
    return sorted_words;
}



with entry {
    print(split_string('hello'));
    print(split_string('Racecar'));
    print(split_string('abcabc'));
}
