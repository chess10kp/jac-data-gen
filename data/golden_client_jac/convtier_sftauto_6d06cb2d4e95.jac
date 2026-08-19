def translate_string(input_string: Any) -> object {
    words = input_string.split(",");
    vowel_words = [];
    for word in words {
        if (word[0].lower() in ['a', 'e', 'i', 'o', 'u']) {
            if ((len(word) % 2) == 1) {
                vowel_words.append(word);
            }
        } else {
            word = word[1:] + word[0];
            if ((len(word) % 2) == 1) {
                vowel_words.append(word);
            }
        }
    }
    return vowel_words;
}



with entry {
    print(translate_string('hello'));
    print(translate_string('Racecar'));
    print(translate_string('abcabc'));
}
