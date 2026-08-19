def reverse_words(string: Any) -> object {
    words = string.split();
    reversed_words = words[::-1];
    reversed_string = ' '.join(reversed_words);
    return reversed_string;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
