def reverse_string(string: Any) -> object {
    words = string.split();
    reversed_words = [];
    for word in reversed(words) {
        reversed_word = word.capitalize().replace('a', 'A').replace('e', 'E').replace(
            'i', 'I'
        ).replace(
            'o', 'O'
        ).replace(
            'u', 'U'
        );
        reversed_words.append(reversed_word);
    }
    reversed_string = ' '.join(reversed_words);
    return reversed_string;
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
