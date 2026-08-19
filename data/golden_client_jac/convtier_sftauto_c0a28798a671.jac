def find_longest_word_without_e(string: Any) -> object {
    def find_longest_word(words: Any, longest_word: Any) -> object {
        if not words {
            return longest_word;
        }
        word = words.pop(0);
        if ('e' not in word) {
            if (len(word) > len(longest_word)) {
                longest_word = word;
            }
        }
        return find_longest_word(words, longest_word);
    }
    words = string.split();
    longest_word = find_longest_word(words, "");
    return longest_word;
}



with entry {
    print(find_longest_word_without_e('hello'));
    print(find_longest_word_without_e('abcabc'));
    print(find_longest_word_without_e('Hello, World!'));
}
