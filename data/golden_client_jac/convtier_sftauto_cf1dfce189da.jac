def find_longest_word(words: Any) -> object {
    return max(words, key=len);
}



with entry {
    print(find_longest_word('hello'));
    print(find_longest_word('Racecar'));
    print(find_longest_word('abcabc'));
}
