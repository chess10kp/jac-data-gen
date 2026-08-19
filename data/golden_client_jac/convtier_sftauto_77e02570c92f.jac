def find_longest_word(sentence: Any) -> object {
    longest_word = "";
    sentence = sentence.split();
    for word in sentence {
        if (('a' not in word) and (len(word) > len(longest_word))) {
            longest_word = word;
        }
    }
    return longest_word;
}



with entry {
    print(find_longest_word('hello'));
    print(find_longest_word('Racecar'));
    print(find_longest_word('level'));
}
