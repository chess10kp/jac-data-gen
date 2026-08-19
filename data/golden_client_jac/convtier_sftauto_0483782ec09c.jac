def reverse_words(text: Any) -> object {
    words = text.split();
    reversed_words = [word[::-1] for word in words];
    reversed_text = ' '.join(reversed_words);
    return reversed_text;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
