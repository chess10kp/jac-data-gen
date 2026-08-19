def find_longest_words(words: Any) -> object {
    longest_words = [];
    max_length = 0;
    for word in words {
        length = len(word);
        if (length > max_length) {
            longest_words = [word];
            max_length = length;
        } elif (length == max_length) {
            longest_words.append(word);
        }
    }
    return longest_words;
}



with entry {
    print(find_longest_words('hello'));
    print(find_longest_words('Racecar'));
    print(find_longest_words('abcabc'));
}
