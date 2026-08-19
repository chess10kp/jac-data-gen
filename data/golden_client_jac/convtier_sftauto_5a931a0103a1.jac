def reverse_words(string: Any) -> object {
    words = string.split();
    reversed_words = [];
    for word in words {
        word = ''.join(
            char
            for char in word
            if char.isalpha()
        );
        reversed_word = word[::-1].capitalize();
        reversed_words.append(reversed_word);
    }
    reversed_string = ' '.join(reversed_words);
    return reversed_string;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
