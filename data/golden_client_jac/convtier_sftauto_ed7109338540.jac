def reverse_words(string: Any) -> object {
    words = string.split(" ");
    reversed_words = [];
    for word in words {
        if (
            (len(word) > 2)
            and word[0].isalpha()
            and (word[0].lower() not in ['a', 'e', 'i', 'o', 'u'])
        ) {
            reversed_word = word[::-1];
            reversed_words.append(reversed_word);
        } else {
            reversed_words.append(word);
        }
    }
    return " ".join(reversed_words);
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
