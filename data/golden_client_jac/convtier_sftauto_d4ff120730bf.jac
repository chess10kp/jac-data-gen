def get_word_sum(word: Any) -> object {
    word_sum = 0;
    for char in word {
        if char.isalpha() {
            word_sum += (ord(char.lower()) - ord('a')) + 1;
        }
    }
    return word_sum;
}



with entry {
    print(get_word_sum('hello'));
    print(get_word_sum('Racecar'));
    print(get_word_sum('abcabc'));
}
