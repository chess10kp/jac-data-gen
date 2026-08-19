def find_longest_word(dictionary: Any) -> object {
    longest_word = "";
    for word in dictionary {
        if ((len(word) >= 8) and (word[0] in 'aeiou') and (word[-1] not in 'aeiou')) {
            if (len(word) > len(longest_word)) {
                longest_word = word;
            }
        }
    }
    return longest_word;
}



with entry {
    print(find_longest_word('hello'));
}
