def find_longest_word_with_vowel(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    words = string.split();
    longest_word = '';
    for word in words {
        if ((word[0].lower() in vowels) and (len(word) > len(longest_word))) {
            longest_word = word;
        }
    }
    return longest_word;
}



with entry {
    print(find_longest_word_with_vowel('hello'));
    print(find_longest_word_with_vowel('abcabc'));
    print(find_longest_word_with_vowel('step on no pets'));
}
