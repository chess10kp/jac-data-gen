def longest_word(sentence: Any) -> object {
    words = sentence.split();
    longest = "";
    for word in words {
        if (('a' in word) and ('b' in word)) {
            continue;
        }
        if ((len(word) >= 5) and (len(word) > len(longest))) {
            longest = word;
        }
    }
    return longest;
}



with entry {
    print(longest_word('hello'));
    print(longest_word('Racecar'));
    print(longest_word('abcabc'));
}
