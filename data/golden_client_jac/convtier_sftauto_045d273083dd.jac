def convert_string(input_string: Any) -> object {
    vowels = {'A': '1', 'E': '2', 'I': '3', 'O': '4', 'U': '5'};
    words = input_string.upper().split();
    converted_words = [];
    for word in words {
        converted_word = '';
        for char in word {
            if (char in vowels) {
                converted_word += vowels[char];
            } else {
                converted_word += char;
            }
        }
        converted_words.append(converted_word);
    }
    return ' '.join(converted_words);
}



with entry {
    print(convert_string('hello'));
    print(convert_string('Racecar'));
    print(convert_string('abcabc'));
}
