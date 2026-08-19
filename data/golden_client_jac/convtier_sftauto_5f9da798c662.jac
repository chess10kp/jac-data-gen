def reverse_words(input_str: Any) -> object {
    words = input_str.split();
    words.reverse();
    reversed_str = ' '.join(words);
    return reversed_str;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
