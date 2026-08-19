def find_longest_word(sentence: Any) -> object {
    words = sentence.split();
    longest_word = '';
    for word in words {
        if (len(word) > len(longest_word)) {
            longest_word = word;
        }
    }
    unique_vowels = [];
    for vowel in `set(longest_word) {
        if (vowel.lower() in 'aeiou') {
            unique_vowels.append(vowel);
        }
    }
    return len(`set(unique_vowels));
}



with entry {
    print(find_longest_word('hello'));
    print(find_longest_word('abcabc'));
}
