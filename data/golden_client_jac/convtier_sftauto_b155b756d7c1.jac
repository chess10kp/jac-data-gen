def find_longest_word(arr: Any) -> object {
    max_length = 0;
    longest_word = "";
    for word in arr {
        if (len(word) > max_length) {
            max_length = len(word);
            longest_word = word;
        }
    }
    return longest_word;
}



with entry {
    print(find_longest_word('hello'));
    print(find_longest_word('Racecar'));
    print(find_longest_word('abcabc'));
}
