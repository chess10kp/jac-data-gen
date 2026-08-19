def reverse_words(sentence: Any) -> object {
    words = sentence.split();
    reversed_words = [word[::-1] for word in words];
    return ' '.join(reversed_words);
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
